clear all
close all

% Load the output files from the LAMMPS simulation, requres the yaml function: https://www.mathworks.com/matlabcentral/fileexchange/106765-yaml
yaml.loadFile("./outputs/dump_probes.Friction_ON.pressure_0.1.freq_0.1.amp_0.001.yaml")
