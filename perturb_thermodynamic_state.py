#!/bin/python
import sys
import os
import numpy as np
import numpy.ma as ma
import netCDF4 as nc

# USAGE
# python Jupyter\ Scripts/Python_Scripts/perturb_thermodynamic_state.py k1 k2 t2 jobid emulator_version_in_iopfiles_directory
# EXAMPLE USAGE:
# python Jupyter\ Scripts/Python_Scripts/perturb_thermodynamic_state.py 75 50 295 322 case_V4.1

k1=np.int(sys.argv[1]) #k1
k2=np.int(sys.argv[2]) #k2
t2=np.float(sys.argv[3]) #t2
job_id=sys.argv[4] # jobid
par_version=sys.argv[5] #version of emulator case

print('the first inversion level is: '+str(k1))
print('the second inversion level is: '+str(k2))
print('the second inversion temperature is: '+str(t2))
print('the case number is: '+job_id)
print('the parameter version is: '+par_version)


# Functions
def find_nearest(array, value):
    array = np.asarray(array)
    idx = (np.abs(array - value)).argmin()
    return array[idx], idx


# Opening IOP file for that case in the script
file_jobid = '/home/.../iop_files/'+str(par_version)+'/DYCOMSrf01_4day_4scam_T_Q_updated_'+str(job_id)+'.nc'
ncfile = nc.Dataset(file_jobid,mode='r+')
ncfile.note="Dycomsrf01 IOP file appended with perturbed T profiles for second inversion"

# fixed parameters
t1= ncfile['T_n'][k1]
t_lev_25 = 281.11999512


# Create the new linspaces

len_u = len(np.arange(25,k2+1))
# CHANGE_U - generate a linear space between the lev 25 and the upper inversion level k2
change_u = np.linspace(t_lev_25, t2, num=len_u)
print('This is the linspace between level 25 and level k2: '+str(change_u))


len_l = len(np.arange(k2,k1+1))
# CHANGE_L - generate a linear space between the upper inversion level k2 and the lower inversion level k1
change_l = np.linspace(t2, t1, num=len_l)
print('This is the linspace between level k2 and level k1: '+str(change_l))


ncfile['T_n'][25:k2] = change_u[:-1]
ncfile['T_n'][k2:k1] = change_l[:-1]

ncfile['T_n'][34] = ncfile['T_n'][34] + 0.7*( t2 - ncfile['T_n'][34])

if k1>74:
    ncfile['T_n'][74] = ncfile['T_n'][74] + 2
    
len_uu = len(np.arange(25,34+1))
# CHANGE_U - generate a linear space between the lev 25 and the upper inversion level k2
change_uu = np.linspace(t_lev_25, ncfile['T_n'][34], num=len_uu)
print('This is the linspace between level 25 and level 34: '+str(change_uu))

len_ul = len(np.arange(34,k2+1))
# CHANGE_U - generate a linear space between the lev 25 and the upper inversion level k2
change_ul = np.linspace(ncfile['T_n'][34],t2, num=len_ul)
print('This is the linspace between level 25 and level k2: '+str(change_ul))

ncfile['T_n'][25:34] = change_uu[:-1]
ncfile['T_n'][34:k2] = change_ul[:-1]

if k1 >74:

    len_lu = len(np.arange(k2,74+1))
    # CHANGE_L - generate a linear space between the upper inversion level k2 and the lower inversion level k1
    change_lu = np.linspace(t2,ncfile['T_n'][74] , num=len_lu)
    print('This is the linspace between level k2 and level k74: '+str(change_lu))

    len_ll = len(np.arange(74,k1+1))
    # CHANGE_L - generate a linear space between the upper inversion level k2 and the lower inversion level k1
    change_ll = np.linspace(ncfile['T_n'][74] , t1, num=len_ll)
    print('This is the linspace between level 74 and level k1: '+str(change_ll))
    ncfile['T_n'][k2:74] = change_lu[:-1]
    ncfile['T_n'][74:k1] = change_ll[:-1]
else:
    ncfile['T_n'][k2:k1] = change_l[:-1]

ncfile['T'][0,:,0,0] = ncfile['T_n'][:]
ncfile['T'][1,:,0,0] = ncfile['T_n'][:]

# Changing q based on updated temp and relative humidity

# calculate updated e_s profile based on new T profile using C-C equation
# Use the existing RH profile and new e_s_updated to work backwards and calculate updated w:


T_prof_new = ncfile['T_n'][:]
lev = ncfile['lev'][:]
RH = ncfile['RH'][:]

# Translating RH profile such that max RH of 113% is achieved at k1, and decreases to min of 9% above k1

RH_new = np.zeros(len(lev))
dif = int(len(lev)) - k1
len_rh_l = len(np.arange(k1,k1+dif))

RH_new[k1:] = np.linspace(RH[71], RH[-1], num=len_rh_l)
RH_new[35:k1]= RH[70]
RH_new[:35]=RH[:35]

e_s_prof_new = 611*( np.exp(17.67*(T_prof_new-273.16)/(T_prof_new-29.66)) ) # saturation vapour pressure in kPa

w_s_new = 0.622*e_s_prof_new/(lev-e_s_prof_new)

w_new = RH_new*w_s_new/100


ncfile['q'][0,:,0,0] = w_new
# ncfile['q'][0,k2:,0,0] = 0.009

ncfile['q'][1,:,0,0] = w_new
# ncfile['q'][1,k2:,0,0] = 0.009

RH_n = ncfile.createVariable('RH_n',np.float32,('lev',)) # note: unlimited dimension is leftmost
RH_n.units = 'percentage' # degrees Kelvin
RH_n.standard_name = 'Updated RH for inversion base height' 
print(RH_n)

RH_n[:] = RH_new[:]

ncfile.close()

print('file appended with updated T and q successfully')

