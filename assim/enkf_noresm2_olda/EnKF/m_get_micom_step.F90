module m_get_micom_step
contains 
subroutine get_micom_step(step, nx, ny)
   use netcdf
   use nfw_mod

   implicit none
   integer, intent(in) :: nx,ny
   integer, dimension(nx,ny), intent(out) :: step
   integer ncid, v_ID

   logical ex

   inquire(file='step.nc',exist=ex)
   if (ex) then
     ! Reading the step file
      call nfw_open('step.nc', nf_nowrite, ncid)
      call nfw_inq_varid('step.nc', ncid,'loca_tt' ,v_ID)
      call nfw_get_var_int('step.nc', ncid, v_ID, step)
      call nfw_close('step.nc', ncid)
   else
      stop 'ERROR: file step.nc is missing'
   endif
end subroutine  get_micom_step
end module  m_get_micom_step
