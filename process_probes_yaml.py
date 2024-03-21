import os
import yaml
import glob
import re

# Specify the directory containing the YAML files
outputs_directory = "./outputs/"

# Use glob to find all YAML files in the outputs directory
yaml_files = glob.glob(os.path.join(outputs_directory, "dump_probes.*.yaml"))

# Define a regular expression pattern to extract the values from the file name. r" enables \. to be treated as just .
pattern = r"dump_probes\.(\w+)\.pressure_([\d.]+)\.freq_([\d.]+)\.amp_([\d.]+)\.yaml"

# Loop through each YAML file found
for yaml_file in yaml_files:
    print("Processing YAML file:", yaml_file)
    # Extract the values from the file name using regular expressions (re.match)
    match = re.match(pattern, os.path.basename(yaml_file))
    if not match:
        print(f"Could not extract values from filename: {yaml_file}")
        continue
    
    friction_status, dimensionless_p, FREQ, AMP = match.groups()

    # Construct the file paths for the output files. f" enables formatted string
    plotdata_probes_zdisp_file = os.path.join(outputs_directory, f"plotdata_probes_zdisp.{friction_status}.pressure_{dimensionless_p}.freq_{FREQ}.amp_{AMP}.txt")
    plotdata_probes_ydisp_file = os.path.join(outputs_directory, f"plotdata_probes_ydisp.{friction_status}.pressure_{dimensionless_p}.freq_{FREQ}.amp_{AMP}.txt")
    plotdata_probes_xdisp_file = os.path.join(outputs_directory, f"plotdata_probes_xdisp.{friction_status}.pressure_{dimensionless_p}.freq_{FREQ}.amp_{AMP}.txt")

    # Initialize an empty list to store timestep data
    timesteps = []

    # Open the YAML file for reading
    with open(yaml_file, "r") as f:
        # Use PyYAML to load all documents in the YAML file
        data = yaml.load_all(f, Loader=yaml.SafeLoader)

        # Loop through each document (timestep) in the YAML file
        for d in data:
            # Append the entire timestep data to the list
            timesteps.append(d)

    # Write data to plotdata_probes_zdisp_file
    with open(plotdata_probes_zdisp_file, 'w') as file:
        # Write header
        file.write("Timestep")
        for N in range(len(timesteps[0]['data'])):
            file.write(f" Probe{N}")
        file.write("\n")

        # Iterate over timesteps
        for timestep in timesteps:
            file.write(f"{timestep['timestep']}")
            for data in timestep['data']:
                file.write(f" {data[4]}")  # Write z-displacement data
            file.write("\n")

    # Write data to plotdata_probes_ydisp_file
    with open(plotdata_probes_ydisp_file, 'w') as file:
        # Write header
        file.write("Timestep")
        for N in range(len(timesteps[0]['data'])):
            file.write(f" Probe{N}")
        file.write("\n")

        # Iterate over timesteps
        for timestep in timesteps:
            file.write(f"{timestep['timestep']}")
            for data in timestep['data']:
                file.write(f" {data[3]}")  # Write y-displacement data
            file.write("\n")

    # Write data to plotdata_probes_xdisp_file
    with open(plotdata_probes_xdisp_file, 'w') as file:
        # Write header
        file.write("Timestep")
        for N in range(len(timesteps[0]['data'])):
            file.write(f" Probe{N}")
        file.write("\n")

        # Iterate over timesteps
        for timestep in timesteps:
            file.write(f"{timestep['timestep']}")
            for data in timestep['data']:
                file.write(f" {data[2]}")  # Write x-displacement data
            file.write("\n")
