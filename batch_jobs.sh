##############################################################################################
# The purpose of this script is to submit a LAMMPS
# job to to a Unix-based (Mac OS) system using bash.

# USAGE:
# in put the following into command line:
# sh this_filename
# or
# bash this_filename

# REQUIREMENTS:
## SOFTWARE:
### Python3
### Octave
### LAMMPS build with GRANULAR and EXTRA_DUMP packages
## FILES:
### data_ICN10000W7.granular
### batch_jobs.script
### script.IC.read.compress
### script.restart.read.ic.wiggle
### process_probes_yaml.py
### process_sinusoidal.m
### plot_mult_probe_zdisp.m
### plot_attenuation_freq.m


# DESCRPTION:
# This script will read in data from
# data_ICN10000W7.granular
# and then create an initial condtion (IC) packing
# script.IC.read.compress
# Then, from that IC, it will run an oscillation
# LAMMPS script called
# script.restart.read.ic.wiggle
# using frequencies you specify in FREQ_LIST.
# Final output will be data file called
# data_attenuation_pressure_(dimensionless_p)_freq_(FREQ).txt 
# and
# plot_attenuation_pressure_(dimensionless_p)_freq_(FREQ).png 
# where (dimensionless_p) and (FREQ) are the variables specified.

# All questions regarding this script send to c.kawamura@me.com

##############################################################################################


##############################################################################################
# Create Packings at desired pressures
##############################################################################################

###############################################
# Run initial calculations WITH shear friction 
# and save restart. Omit this step if you already
# have restarts.
###############################################
# PRESSURE_LIST=(0.001)

# for PRESSURE in "${PRESSURE_LIST[@]}"
# do
#     ./lmp -var fric 1 -var AMP 0 -var dimensionless_p $PRESSURE -in ./script.IC.read.compress
# done

##############################################################################################
# Perform oscillations at desired frequencies with pressures (must have restart file) from
# previous packing creation.
##############################################################################################
# Define the list of frequencies
FREQ_LIST=(1 0.1) # 

# Define the list of pressures
# PRESSURE_LIST=(0.1 0.01 0.001)
PRESSURE_LIST=(0.1)

for PRESSURE in "${PRESSURE_LIST[@]}"
do
    ###############################################p
    # Use output "restart" file from above and 
    # wiggle (vibrate) the bottom face with different
    # frequencies and amplitudes.
    ###############################################
    # Remove existing attenuation data file if there is one
    rm ./outputs/attenuation_data.txt

    # Iterate over the frequencies
    for FREQ in "${FREQ_LIST[@]}"
    do
        # Run LAMMPS simulation
        ./lmp -l ./outputs/log.lammps -var fric 1 -var AMP 0.001 -var FREQ $FREQ -var dimensionless_p $PRESSURE -var dimensionless_gamma_n .9 -in ./script.restart.read.ic.wiggle

        # Process probe data with Python script
        python3 process_probes_yaml.py

        # Fix attenuation in Octave
        octave -q process_sinusoidal.m
    done

    # Plot attenuation data for all frequencies
    octave -q plot_attenuation_freq.m
done