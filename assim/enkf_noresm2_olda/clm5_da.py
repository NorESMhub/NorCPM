import os
import sys
import numpy as np
import netCDF4 as nc
from datetime import datetime
# ============================== configuration ===============================
DIR = './'
OBS_DIR = './INPUT_SM'

# CLM5 vertical grid (layer thickness in m). Verify against your case.
DZ_CLM5 = np.array([0.02, 0.04, 0.06, 0.08, 0.12, 0.16, 0.20, 0.24, 0.28, 0.32,
                    0.36, 0.40, 0.44, 0.54, 0.64, 0.74, 0.84, 0.94, 1.04, 1.14])
NSOI_CLM5 = 20          # hydrologically active soil layers (nlevsoi)
NSNO_DEFAULT = 12       # CLM5 default nlevsno (used if 'levsno' dim is missing)

RHO_W, RHO_I = 1000.0, 917.0
FILL = 1.0e30

LUN_SOIL, LUN_CROP = 1, 2        # vegetated/bare soil + crop only (DART)

OBS_DEPTH = 0.05      # m; None = top layer only, 0.05 = depth-weighted 0-5 cm operator
SM_ERR = 0.05         # m3/m3
SWE_ERR = 0.02        # MUST be in the same units as H2OSNO (mm)
OUTLIER = 3.0          
MIN_ELIG_WEIGHT = 0.05
VAR_MIN = 1.0e-12

SM_SNOWFREE_MM = 1.0
FROZEN_T = 273.15

UPDATE_TEMP = False
VERT_LOC = 3.0         
TEMP_LOC = 0.5
TEMP_CLAMP = 2.0

THETA_MIN = 0.01
THETA_SAT = 0.45       
SWE_MIN = 1.0         
LOC_SWE = 1.0

# set at run time by configure_layout()
NSNO = NSOIL = None
SNOW = SOIL = None
DZ = ZI = None

def configure_layout(ds):
    global NSNO, NSOIL, SNOW, SOIL, DZ, ZI
    NSNO = ds.dimensions['levsno'].size if 'levsno' in ds.dimensions else NSNO_DEFAULT
    NSOIL = NSOI_CLM5
    SNOW = slice(0, NSNO)
    SOIL = slice(NSNO, NSNO + NSOIL)
    DZ = DZ_CLM5.copy()
    ZI = np.concatenate([[0.0], np.cumsum(DZ)])


# =============================== helpers ====================================
def obs_layer_weights(depth=OBS_DEPTH):
    w = np.zeros(NSOIL)
    if depth is None:
        w[0] = 1.0
        return w
    ov = np.clip(np.minimum(ZI[1:], depth) - ZI[:-1], 0.0, None)
    return ov / ov.sum()


def _first(ds, *names):
    for n in names:
        if n in ds.variables:
            return np.asarray(ds.variables[n][:])
    avail = [v for v in ds.variables if v.startswith(('cols1d', 'grid1d'))]
    raise KeyError(f"None of {names} in restart. Available: {avail}")


def read_column_meta(ds, nlon, ng):
    """Column -> obs-grid mapping, area weights, eligibility (DART landunit localisation)."""
    ityp = _first(ds, 'cols1d_ityplun').astype(int)
    wt = _first(ds, 'cols1d_wtgcell', 'cols1d_wtxy').astype(float)

    if 'cols1d_ixy' in ds.variables and 'cols1d_jxy' in ds.variables:
        ixy = _first(ds, 'cols1d_ixy').astype(int)
        jxy = _first(ds, 'cols1d_jxy').astype(int)
        gidx = (jxy - 1) * nlon + (ixy - 1)
    elif 'cols1d_gridcell_index' in ds.variables and 'grid1d_ixy' in ds.variables:
        gi = _first(ds, 'cols1d_gridcell_index').astype(int) - 1
        ixy = _first(ds, 'grid1d_ixy').astype(int)[gi]
        jxy = _first(ds, 'grid1d_jxy').astype(int)[gi]
        gidx = (jxy - 1) * nlon + (ixy - 1)
    else:
        # assumes obs are stored in CLM land-gridcell order
        gidx = _first(ds, 'cols1d_gridcell_index').astype(int) - 1

    active = (_first(ds, 'cols1d_active').astype(bool)
              if 'cols1d_active' in ds.variables else np.ones(ityp.shape, bool))
    elig = np.isin(ityp, [LUN_SOIL, LUN_CROP]) & (wt > 0) & active & (gidx >= 0) & (gidx < ng)

    watsat = None
    if 'WATSAT' in ds.variables:
        watsat = np.asarray(ds.variables['WATSAT'][:, :NSOIL], float)
    return dict(gidx=gidx, wt=wt, elig=elig, watsat=watsat)


def grid_mean(vals, g, w, ng):
    wsum = np.bincount(g, weights=w, minlength=ng)
    out = np.full((ng, vals.shape[1]), np.nan)
    for k in range(vals.shape[1]):
        out[:, k] = np.bincount(g, weights=w * vals[:, k], minlength=ng)
    with np.errstate(all='ignore'):
        out /= wsum[:, None]
    out[wsum <= 0] = np.nan
    return out, wsum


def eakf_increments(hx, y, r, valid):
    with np.errstate(all='ignore'):
        mu = hx.mean(axis=1)
        var = hx.var(axis=1, ddof=1)
        innov = y - mu
        ok = (valid & np.isfinite(mu) & (var > VAR_MIN)
              & (np.abs(innov) <= OUTLIER * np.sqrt(var + r)))
        var_a = 1.0 / (1.0 / var + 1.0 / r)
        mu_a = var_a * (mu / var + y / r)
        hx_a = mu_a[:, None] + np.sqrt(var_a / var)[:, None] * (hx - mu[:, None])
        dy = np.where(ok[:, None], hx_a - hx, 0.0)
    return dy, np.where(ok, var, np.inf), np.where(valid, innov, np.nan), ok


def regress_increment(Xp, hx, dy, var_safe, g, loc):
    ens = Xp.shape[2]
    hxp = hx - hx.mean(axis=1, keepdims=True)
    hxp = np.nan_to_num(hxp[g])
    cov = np.einsum('nsk,nk->ns', Xp, hxp) / (ens - 1.0)
    reg = cov / var_safe[g][:, None]
    return loc[None, :, None] * reg[:, :, None] * dy[g][:, None, :]


def inflate(X, infl):
    m = X.mean(axis=-1, keepdims=True)
    return m + infl * (X - m)


def isbad(a):
    return ~np.isfinite(a) | (np.abs(a) > FILL)


def read_obs(rdate):
    path = os.path.join(OBS_DIR, f"CCI_sm_obs_{rdate}.nc")
    if not os.path.exists(path):
        return None, None
    sm = swe = None
    with nc.Dataset(path, 'r') as d:
        if 'sm' in d.variables:
            sm = np.ma.filled(d.variables['sm'][:], np.nan).astype(float)
        if 'swe_assimilable' in d.variables:
            swe = np.ma.filled(d.variables['swe_assimilable'][:], np.nan).astype(float)
    return sm, swe


# ================================ driver ====================================
def sm_da_s2s(rdate: str, en: int, infla: float):
    ens, infl = int(en), float(infla)
    #formatted_date = datetime.strptime(str(rdate), "%Y%m%d").strftime("%Y-%m-%d")
    files = [os.path.join(DIR, f"clm.rda.{i:03d}.{rdate}.nc") for i in range(1, ens + 1)]
    print(files)
    sm_obs_2d, swe_obs_2d = read_obs(rdate)
    ref = sm_obs_2d if sm_obs_2d is not None else swe_obs_2d
    if ref is None:
        print(f"No observations for {rdate}; restarts left unchanged.")
        return
    ng = ref.size
    nlon = ref.shape[-1] if ref.ndim == 2 else None
    y_sm = sm_obs_2d.ravel() if sm_obs_2d is not None else None
    y_swe = swe_obs_2d.ravel() if swe_obs_2d is not None else None

    liq_l, ice_l, tsoi_l, swe_l = [], [], [], []
    meta = None
    for f in files:
        with nc.Dataset(f, 'r') as ds:
            ds.set_auto_mask(False)
            if meta is None:
                configure_layout(ds)
                if nlon is None:
                    nlon = ds.dimensions['lon'].size
                meta = read_column_meta(ds, nlon, ng)
            liq_l.append(np.asarray(ds.variables['H2OSOI_LIQ'][:, SOIL], float))
            ice_l.append(np.asarray(ds.variables['H2OSOI_ICE'][:, SOIL], float))
            tsoi_l.append(np.asarray(ds.variables['T_SOISNO'][:, SOIL], float))
            swe_l.append(np.asarray(ds.variables['H2OSNO'][:], float)
                         if 'H2OSNO' in ds.variables else None)
    liq = np.stack(liq_l, -1)            # [ncol, NSOIL, ens] kg/m2
    ice = np.stack(ice_l, -1)
    tsoi = np.stack(tsoi_l, -1)
    swe = np.stack(swe_l, -1) if swe_l[0] is not None else None

    gidx, wt, elig = meta['gidx'], meta['wt'], meta['elig']
    bad_soil = (isbad(liq) | isbad(ice) | isbad(tsoi)).any(axis=(1, 2))
    ec = np.where(elig & ~bad_soil)[0]
    g_e, w_e = gidx[ec], wt[ec]

    # ===================== SOIL MOISTURE =====================
    sm_upd = None
    innov_sm = np.full((ng, 1), np.nan)
    if y_sm is not None and ec.size > 0:
        dz3 = DZ[None, :, None]
        th = liq[ec] / (RHO_W * dz3)
        th_ice = ice[ec] / (RHO_I * dz3)
        T = tsoi[ec]

        th_x = inflate(th, infl)
        T_x = inflate(T, infl) if UPDATE_TEMP else T

        hx_col = np.einsum('l,nlk->nk', obs_layer_weights(), th_x)
        hx, wsum = grid_mean(hx_col, g_e, w_e, ng)

        t_top, _ = grid_mean(T[:, 0, :], g_e, w_e, ng)
        if swe is not None:
            swe_g, _ = grid_mean(np.nan_to_num(swe[ec]), g_e, w_e, ng)
            snowfree = np.nan_to_num(swe_g.mean(1), nan=0.0) < SM_SNOWFREE_MM
        else:
            snowfree = np.ones(ng, bool)
        unfrozen = np.nan_to_num(t_top.mean(1), nan=0.0) >= FROZEN_T

        valid = (np.isfinite(y_sm) & (y_sm >= 0) & (y_sm <= 1)
                 & (wsum >= MIN_ELIG_WEIGHT) & snowfree & unfrozen)
        r = np.full(ng, SM_ERR ** 2)
        dy, var_s, innov, ok = eakf_increments(hx, y_sm, r, valid)
        innov_sm[:, 0] = innov
        print(f"[{rdate}] SM obs assimilated in {ok.sum()} gridcells")

        k = np.arange(NSOIL)
        loc_sm = np.ones(NSOIL) if VERT_LOC is None else np.exp(-k / VERT_LOC)
        if UPDATE_TEMP:
            X = np.concatenate([th_x, T_x], axis=1)
            loc = np.concatenate([loc_sm, np.exp(-k / 4.0) * TEMP_LOC])
        else:
            X, loc = th_x, loc_sm
        Xp = X - X.mean(axis=2, keepdims=True)
        X_ana = X + regress_increment(Xp, hx, dy, var_s, g_e, loc)

        th_sat = (meta['watsat'][ec][:, :, None] if meta['watsat'] is not None else THETA_SAT)
        th_ana = np.clip(X_ana[:, :NSOIL, :], THETA_MIN, np.maximum(th_sat - th_ice, THETA_MIN))
        T_ana = (T + np.clip(X_ana[:, NSOIL:, :] - T, -TEMP_CLAMP, TEMP_CLAMP)
                 if UPDATE_TEMP else T)

        upd = ok[g_e][:, None, None]
        liq_new = np.where(upd, th_ana, th) * RHO_W * dz3
        T_new = np.where(upd, T_ana, T) if UPDATE_TEMP else None
        sm_upd = (ec, liq_new, T_new)

    # ======================== SNOW (SWE) ========================
    swe_upd = None
    innov_swe = np.full((ng, 1), np.nan)
    if swe is not None and y_swe is not None:
        es = np.where(elig & ~isbad(swe).any(axis=1))[0]     # any FillValue member -> skip
        if es.size > 0:
            g_s, w_s = gidx[es], wt[es]
            s = swe[es]
            allow = (s > 0).any(axis=1)                       # DART snow safety rule
            s_x = np.maximum(0.0, inflate(s, infl))
            hx_s, wsum_s = grid_mean(s_x, g_s, w_s, ng)

            valid = np.isfinite(y_swe) & (y_swe >= 0) & (wsum_s >= MIN_ELIG_WEIGHT)
            r = np.full(ng, SWE_ERR ** 2)
            dy, var_s, innov, ok = eakf_increments(hx_s, y_swe, r, valid)
            innov_swe[:, 0] = innov
            print(f"[{rdate}] SWE obs assimilated in {ok.sum()} gridcells")

            Xp = (s_x - s_x.mean(axis=1, keepdims=True))[:, None, :]
            dswe = regress_increment(Xp, hx_s, dy, var_s, g_s, np.array([LOC_SWE]))[:, 0, :]
            s_post = np.maximum(0.0, s_x + dswe)
            changed = ok[g_s] & allow
            swe_upd = (es[changed], s_post[changed])

    write_restarts(files, sm_upd, swe_upd)
    write_innovation(rdate, innov_sm, innov_swe)


# ================================ output ====================================
def _scale(ds, name, cols, ratio):
    if name not in ds.variables or cols.size == 0:
        return
    v = ds.variables[name]
    a = np.asarray(v[:])
    sub = a[cols]
    r = ratio if a.ndim == 1 else ratio[:, None]
    a[cols] = np.where(np.abs(sub) < FILL, sub * r, sub)
    v[:] = a


def repartition_member(ds, cols, post):
    """
    Simplified snow repartitioning (not DART's full dart_to_clm routine):
      - columns with snow layers: rescale layer liquid/ice mass, DZSNO, ZSNO, ZISNO
        and SNOW_DEPTH so layer-summed SWE equals the posterior;
      - CLM5 columns with snow but no layers: update H2OSNO_NO_LAYERS and SNOW_DEPTH;
      - columns with no snow at all are left alone (no snow creation).
    """
    vl, vi = ds.variables['H2OSOI_LIQ'], ds.variables['H2OSOI_ICE']
    liq_s, ice_s = vl[:, SNOW], vi[:, SNOW]
    lc, ic = liq_s[cols], ice_s[cols]
    lv, iv = np.abs(lc) < FILL, np.abs(ic) < FILL
    lsum = np.where(lv, lc, 0.0).sum(1) + np.where(iv, ic, 0.0).sum(1)
    act = lsum > 0
    target = np.maximum(post, SWE_MIN)

    nl = np.zeros(cols.size, bool)
    if 'H2OSNO_NO_LAYERS' in ds.variables:
        vn = ds.variables['H2OSNO_NO_LAYERS']
        an = np.asarray(vn[:])
        prior_nl = an[cols]
        nl = (~act) & (prior_nl > 0) & (np.abs(prior_nl) < FILL)
        if nl.any():
            an[cols[nl]] = target[nl]
            vn[:] = an
            _scale(ds, 'SNOW_DEPTH', cols[nl], target[nl] / prior_nl[nl])

    if act.any():
        c_act = cols[act]
        ratio = target[act] / lsum[act]
        liq_s[c_act] = np.where(lv[act], lc[act] * ratio[:, None], lc[act])
        ice_s[c_act] = np.where(iv[act], ic[act] * ratio[:, None], ic[act])
        vl[:, SNOW] = liq_s
        vi[:, SNOW] = ice_s
        for name in ('DZSNO', 'ZSNO', 'ZISNO', 'SNOW_DEPTH'):
            _scale(ds, name, c_act, ratio)

    upd = act | nl
    if upd.any():
        v = ds.variables['H2OSNO']
        a = np.asarray(v[:])
        a[cols[upd]] = target[upd]
        v[:] = a


def write_restarts(files, sm_upd, swe_upd):
    for k, f in enumerate(files):
        with nc.Dataset(f, 'r+') as ds:
            ds.set_auto_mask(False)
            if sm_upd is not None:
                ec, liq_new, T_new = sm_upd
                v = ds.variables['H2OSOI_LIQ']
                a = v[:, SOIL]
                a[ec] = liq_new[:, :, k]
                v[:, SOIL] = a
                if T_new is not None:
                    v = ds.variables['T_SOISNO']
                    a = v[:, SOIL]
                    a[ec] = T_new[:, :, k]
                    v[:, SOIL] = a
            if swe_upd is not None and swe_upd[0].size > 0:
                repartition_member(ds, swe_upd[0], swe_upd[1][:, k])


def write_innovation(rdate, innov_sm, innov_swe):
    #formatted_date = datetime.strptime(str(rdate), "%Y%m%d").strftime("%Y-%m-%d")
    with nc.Dataset(os.path.join(DIR, f"Innovation-{rdate}.nc"), 'w', format='NETCDF4') as ds:
        ds.createDimension('row', innov_sm.shape[0])
        ds.createDimension('col', 1)
        ds.createVariable('innovation', 'f8', ('row', 'col'), fill_value=False)[:] = innov_sm
        ds.createVariable('innovation_swe', 'f8', ('row', 'col'), fill_value=False)[:] = innov_swe


if __name__ == "__main__":
    if len(sys.argv) >= 4:
        sm_da_s2s(rdate=sys.argv[1], en=int(sys.argv[2]), infla=float(sys.argv[3]))

