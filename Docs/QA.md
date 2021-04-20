# Overview
Q: What is NorCPM?  
A: NorCPM is a set of scripts and codes to run NorESM in multiple members with or without ocean data assimilation.  

Q: What is the difference between members?  
A: NorCPM assume the initial condition would be different between members. There are scripts to create small perturbed temperature (10^-6) from ocean model restart file. Check the description in Tools/create_perturb_SST.sh for more detail. The variability would be stabilized around 10 years simulation.  

Q: What are the files in SourceMods.noresm2?  
A: SourceMods.noresm2/src.drv/cime_comp_mod.F90: This is the major modification of NorCPM. Which split global_comm and change work dir make model run with multiple members in 1 job.  
   SourceMods.noresm2/src.clm/controlMod.F90: It fix a bug to allow branch run without unnecessary input file. See:  
                                               https://github.com/ESCOMP/CTSM/issues/786  
   SourceMods.noresm2/template.st_archive_NorCPM_mem01: Run st_archive for members other than 1. But it need copy to NorESM directory. Not necessary.  

# Run without data assimilation
Q: What is the difference between run with NorCPM and run multiple individual cases?  
A: These 2 method are same in result output. However one can type fewer command with NorCPM.   

Q: What are the right steps to get a ensemble run.  
A: 1. Copy and modify a Prediction/use_cases/template.in.  
   2. Use Prediction/create_template.sh template.in, which create and build the first member. You can check it is correct or not.  
   3. Prediction/create_ensemble.sh template.in, which clone and do necessary modify to members other than first.  
   4. Prediction/submit_ensemble.sh template.in, which submit job to run ensemble members and archiving scripts.  

Q: How do I adjust the tasks of components?  
A: For simplify, NorCPM set all components run sequencally. One can change it in the setting file(template.in) before create 1st member. See the variable PRECASESETUP about 'xmlchange NTASKS'. Remember the variable MEMBER_PES must be set as total tasks for 1 member cost.  

Q: How do I change the run period of a exist NorCPM case?  
A: Change the STOP_N and STOP_OPTION in setting file(template.in). And use the submit_ensemble.sh. It will be applied.  

# Run with data assimilation  
Q: How it work?  
A: The script Analysis/submit_reanalysis.sh modify the ocean restart files with ensemble Kalmann filter, then run model 1 month. And so on.  

Q: How do I create a case for data assimilation?  
A: Yes, use the scripts in Prediction directory to create case, and run it for 14 model days. After that you can use Analysis/submit_reanalysis.sh.  

Q: Why the submit commands are such different between with and without data assimilation.  
A: For analysis run, it would be complicated under queue system. So keep everything in one script would be better.  

Q: What are ensave, EnKF and micom_ensemble_init? And where are they?  
A: These are program for data assimilation, can be found on Betzy or Fram at following path:  
   /cluster/shared/noresm/norcpm/bin  
   One can use them by setting the WORKSHARED variable in Analysis setting to:  
   /cluster/shared/noresm/norcpm  
   If one is using NorCPM other than Betzy and Fram, or want to compile own version, see HOWTO-Compile.md

# Compiling the data assimilation code
Q: Why and when I have to compile the data assimilation code by myself?
A: You can use pre-build binaries if you want to run on Betzy or Fram. But you will need to build them if want to run it on other machine or build your own version. 

Q: Where are the codes?
A: Check the NorCPM/Analysis/lib/README and Makefile.

Q: What do you mean 'build them all'?
A: There are two versions of EnKF. One is anomaly field and full field. The Makefile build both and move them to WORKSHARED/bin.

