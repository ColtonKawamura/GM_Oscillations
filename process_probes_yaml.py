import yaml

# Try to import CSafeLoader from PyYAML; if not available, use SafeLoader
try:
    from yaml import CSafeLoader as YamlLoader
except ImportError:
    from yaml import SafeLoader as YamlLoader

# Initialize an empty list to store timestep data
timesteps = []

# Open the YAML file for reading
with open("dump_probes.yaml", "r") as f:
    # Use PyYAML to load all documents in the YAML file
    data = yaml.load_all(f, Loader=YamlLoader)

    # Loop through each document (timestep) in the YAML file
    for d in data:
        # Print information about the current timestep
        print('Processing timestep %d' % d['timestep'])
        # Append the entire timestep data to the list
        timesteps.append(d)

print('Read %d timesteps from yaml dump' % len(timesteps))

with open('plotdata_probes_zdisp.txt', 'w') as file:
    # Write header
    file.write("Timestep")

    # Iterate over data columns for the first timestep to generate header
    for N in range(len(timesteps[0]['data'])):
        file.write(" Probe{}".format(N))

    file.write("\n")

    # Iterate over timesteps
    for n in range(len(timesteps)):
        # Write timestep number
        file.write("{}".format(timesteps[n]['timestep']))

        # Write data columns for each timestep
        for N in range(len(timesteps[0]['data'])):
            file.write(" {}".format(timesteps[n]['data'][N][4]))

        file.write("\n")


with open('plotdata_probes_ydisp.txt', 'w') as file:
    # Write header
    file.write("Timestep")

    # Iterate over data columns for the first timestep to generate header
    for N in range(len(timesteps[0]['data'])):
        file.write(" Probe{}".format(N))

    file.write("\n")

    # Iterate over timesteps
    for n in range(len(timesteps)):
        # Write timestep number
        file.write("{}".format(timesteps[n]['timestep']))

        # Write data columns for each timestep
        for N in range(len(timesteps[0]['data'])):
            file.write(" {}".format(timesteps[n]['data'][N][3]))

        file.write("\n")

with open('plotdata_probes_xdisp.txt', 'w') as file:
    # Write header
    file.write("Timestep")

    # Iterate over data columns for the first timestep to generate header
    for N in range(len(timesteps[0]['data'])):
        file.write(" Probe{}".format(N))

    file.write("\n")

    # Iterate over timesteps
    for n in range(len(timesteps)):
        # Write timestep number
        file.write("{}".format(timesteps[n]['timestep']))

        # Write data columns for each timestep
        for N in range(len(timesteps[0]['data'])):
            file.write(" {}".format(timesteps[n]['data'][N][2]))

        file.write("\n")