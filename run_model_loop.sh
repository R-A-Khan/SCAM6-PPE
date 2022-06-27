#!/bin/bash

# Usage:
# cat parameter_file | xargs -n 10 ./run_model_loop.sh

 thisjob=$1
 sig_AI=$2
 sig_C=$3
 hyg_SOA=$4
 hyg_D=$5
 hyg_SS=$6
 sc_f_aer=$7
 lev=$8
 lev2=$9
 t_lev2=${10}



 echo "running model for input: ${thisjob}"
 echo " sig_AI is $sig_AI, hyg_SS is $hyg_SS. scale factor is $sc_f_aer. Second Inversion leveltemperature is ${t_lev2}."



# #create case
# #set up case

 dir_name=EM_4.3_CASE_${thisjob}

 cd /.../scripts/

./create_clone --case /home/.../$dir_name --clone /home/.../Emulator_Base_Case --user-mods-dir /home/.../usermods_dirs/scam_dycomsRF01 --keepexe --mach-dir /home/.../machines --project $PROJ_NAME --cime-output-root /.../emulator-out

cd /home/.../cases/$dir_name


par_version=case_V4.3
mkdir -p /.../par_files/$par_version
mkdir -p /.../ic_em_files/$par_version/
mkdir -p /.../iop_files/$par_version/


# # replace env_run with new values 
# # copy relevant nl directory to local folder, append name with run_id
# # replace the values using nco

echo 'Initiating parameter input into NC file'

module load NCO/4.7.9-nsc5

# LOADING NEW SIGMA AND HYGRO VALUES INTO PARAMETER FILES

# Aitken Mode (sig_AI)
ncap2 -s "sigmag=${sig_AI}" /.../mam4_mode2_rrtmg_aitkendust_c141106.nc /.../par_files/$par_version/mam4_mode2_rrtmg_aitkendust_c141106_${thisjob}.nc

# Coarse Mode (sig_C)
ncap2 -s "sigmag=${sig_C}" /.../mam4_mode3_rrtmg_aeronetdust_sig1.2_dgnl.40_c150219.nc /.../par_files/$par_version/mam4_mode3_rrtmg_aeronetdust_sig1.2_dgnl.40_c150219_${thisjob}.nc


# SOA (hyg_SOA)
ncap2 -s "hygroscopicity=${hyg_SOA}" /.../ocphi_rrtmg_c100508.nc /.../par_files/$par_version/ocphi_rrtmg_c100508_${thisjob}.nc


# Dust (hyg_D)
ncap2 -s "hygroscopicity=${hyg_D}" /.../dust_aeronet_rrtmg_c141106.nc /.../par_files/$par_version/dust_aeronet_rrtmg_c141106_${thisjob}.nc


# Seasalt (hyg_SS)
ncap2 -s "hygroscopicity=${hyg_SS}" /.../ssam_rrtmg_c100508.nc  /.../par_files/$par_version/ssam_rrtmg_c100508_${thisjob}.nc 

echo 'Parameter replacement completed.'


cp /home/.../DYCOMSrf01_4day_4scam_T_Q_updated.nc /.../$par_version/DYCOMSrf01_4day_4scam_T_Q_updated_${thisjob}.nc

module load Python/3.8.3-anaconda-2020.07-extras-nsc1

python /home/sm_ramkh/Jupyter\ Scripts/Python_Scripts/pert_IOP_T_inv_v4-3.py $lev $lev2 $t_lev2 $thisjob $par_version

echo 'IOP replacement completed.'

#Change initial condition to scaled value for 5 aerosol
ncap2 -s  "bc_a1=${sc_f_aer}*bc_a1;bc_a4=${sc_f_aer}*bc_a4;so4_a1=${sc_f_aer}*so4_a1;so4_a2=${sc_f_aer}*so4_a2;so4_a3=${sc_f_aer}*so4_a3" /home/sm_ramkh/inic_files/CESM2.F2000climo.IOP_SITES.cam.i.0003-07-01-00000.regrid.Gaus_64x128.nc /.../ic_em_files/$par_version/CESM2.F2000climo.IOP_SITES.cam.i.0003-07-01-00000.regrid.Gaus_64x128_v4.3_${thisjob}.nc

echo 'IC replacement completed.'


cat >> user_nl_cam << EOF
 ncdata         = "/.../ic_em_files/$par_version/CESM2.F2000climo.IOP_SITES.cam.i.0003-07-01-00000.regrid.Gaus_64x128_v4.3_${thisjob}.nc"
  iopfile        = "/.../iop_files/$par_version/DYCOMSrf01_4day_4scam_T_Q_updated_${thisjob}.nc"
 iradsw         = 1
 iradlw         = 1
 use_topo_file          = .true.  
 mfilt          = 2500
 scm_relax_fincl = 'bc_a1', 'bc_a4', 'dst_a1', 'dst_a2', 'dst_a3', 'ncl_a1', 'ncl_a2',
                   'ncl_a3', 'num_a1', 'num_a2', 'num_a3',
                   'num_a4', 'pom_a1', 'pom_a4', 'so4_a1', 'so4_a2', 'so4_a3', 'soa_a1', 'soa_a2' 
 nhtfrq         =1
 fincl1= 'CDNUMC', 'AQSNOW','ANSNOW','FREQSL','LS_FLXPRC','ASDIR','AREI','FDS','FLDS','FLDSC','FSNTOA','FSNTOAC'
 scm_use_obs_t          = .true.
 scm_use_obs_uv         = .true.



 mode_defs        = 'mam4_mode1:accum:=', 'A:num_a1:N:num_c1:num_mr:+',
         'A:so4_a1:N:so4_c1:sulfate:/.../sulfate_rrtmg_c080918.nc:+', 'A:pom_a1:N:pom_c1:p-organic:/.../ocpho_rrtmg_c130709.nc:+',
         'A:soa_a1:N:soa_c1:s-organic:/.../par_files/$par_version/ocphi_rrtmg_c100508_${thisjob}.nc:+', 'A:bc_a1:N:bc_c1:black-c:/.../bcpho_rrtmg_c100508.nc:+',
         'A:dst_a1:N:dst_c1:dust:/.../par_files/$par_version/dust_aeronet_rrtmg_c141106_${thisjob}.nc:+', 'A:ncl_a1:N:ncl_c1:seasalt:/.../par_files/$par_version/ssam_rrtmg_c100508_${thisjob}.nc',
         'mam4_mode2:aitken:=', 'A:num_a2:N:num_c2:num_mr:+',
         'A:so4_a2:N:so4_c2:sulfate:/.../sulfate_rrtmg_c080918.nc:+', 'A:soa_a2:N:soa_c2:s-organic:/.../par_files/$par_version/ocphi_rrtmg_c100508_${thisjob}.nc:+',
         'A:ncl_a2:N:ncl_c2:seasalt:/.../par_files/$par_version/ssam_rrtmg_c100508_${thisjob}.nc:+', 'A:dst_a2:N:dst_c2:dust:/.../par_files/$par_version/dust_aeronet_rrtmg_c141106_${thisjob}.nc',
         'mam4_mode3:coarse:=', 'A:num_a3:N:num_c3:num_mr:+',
         'A:dst_a3:N:dst_c3:dust:/.../par_files/$par_version/dust_aeronet_rrtmg_c141106_${thisjob}.nc:+', 'A:ncl_a3:N:ncl_c3:seasalt:/.../par_files/$par_version/ssam_rrtmg_c100508_${thisjob}.nc:+',
         'A:so4_a3:N:so4_c3:sulfate:/.../sulfate_rrtmg_c080918.nc', 'mam4_mode4:primary_carbon:=',
         'A:num_a4:N:num_c4:num_mr:+', 'A:pom_a4:N:pom_c4:p-organic:/.../ocpho_rrtmg_c130709.nc:+',
         'A:bc_a4:N:bc_c4:black-c:/.../bcpho_rrtmg_c100508.nc'

 rad_climate = 
 'A:Q:H2O', 'N:O2:O2', 'N:CO2:CO2', 'N:ozone:O3',
 'N:N2O:N2O', 'N:CH4:CH4', 'N:CFC11:CFC11', 'N:CFC12:CFC12',
 'M:mam4_mode1:/.../mam4_mode1_rrtmg_aeronetdust_sig1.6_dgnh.48_c140304.nc',
 "M:mam4_mode2:/.../par_files/$par_version/mam4_mode2_rrtmg_aitkendust_c141106_${thisjob}.nc",
 "M:mam4_mode3:/.../par_files/$par_version/mam4_mode3_rrtmg_aeronetdust_sig1.2_dgnl.40_c150219_${thisjob}.nc", 
 'M:mam4_mode4:/.../mam4_mode4_rrtmg_c130628.nc',
 'N:VOLC_MMR1:/.../volc_camRRTMG_byradius_sigma1.6_mode1_c170214.nc',
 'N:VOLC_MMR2:/.../volc_camRRTMG_byradius_sigma1.6_mode2_c170214.nc',
 'N:VOLC_MMR3:/.../volc_camRRTMG_byradius_sigma1.2_mode3_c170214.nc'

EOF


./preview_namelists

echo "Submitting run for parameterset ${thisjob} now."

./case.submit
