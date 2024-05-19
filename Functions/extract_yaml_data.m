function [index_particles, position_particles, time_vector] = extract_yaml_data(file_path)
    % Read the entire file content; needs to be file_path = './outputs/dump_probes.Friction_ON.pressure_0.1.freq_0.1.amp_0.001.yaml';
    file_content = fileread(file_path);

    % Split the content by the document separator '---'
    documents = regexp(file_content, '---', 'split');

    % Initialize variables to hold the extracted data
    index_particles = [];
    position_particles = [];
    time_vector = [];

    % Loop through each document and parse the data
    for i = 1:length(documents)
        doc = strtrim(documents{i});
        if isempty(doc)
            continue;
        end

        % Extract timestep
        timestep_pattern = 'timestep:\s+(\d+)'; % Matches emptyspace "\s" and "+" any gruop of digits "(\d+)"
        timestep_tokens = regexp(doc, timestep_pattern, 'tokens'); % saves the regular expression "regexp" from "doc" that matches "timestep_pattern". "token" only saves that which is in parathesis
        if ~isempty(timestep_tokens)
            timestep = str2double(timestep_tokens{1}{1}); % Turns a string to a number. the first {1} access the first cell, the second {1} pulls the actual digit
            time_vector(end + 1) = timestep; 
        end

        % Extract particle data
        data_pattern = 'data:\s*\n((?:\s*-\s*\[.*?\]\n?)*)'; % the "*" allows for multiple "\s", "\n" new line, "-\s" makes sure it starts with new line, "\[.*?\]" matches anything inside brackets as small a possible
        data_tokens = regexp(doc, data_pattern, 'tokens', 'dotexceptnewline'); % "dotexceptnewline matches any " . " NOT on a new line
        if ~isempty(data_tokens)
            data_str = data_tokens{1}{1};
            data_lines = regexp(data_str, '\-\s*\[(.*?)\]', 'tokens');
            for j = 1:length(data_lines)
                data_line = str2num(data_lines{j}{1}); 
                particle_id = data_line(1);
                x = data_line(3);
                y = data_line(4);
                z = data_line(5);

                % Append to the index_particles and position_particles
                index_particles = [index_particles; particle_id];
                position_particles = [position_particles; x, y, z];
            end
        end
    end

    % Convert index_particles to unique values
    index_particles = unique(index_particles);

    % Reshape position_particles into a 3D matrix (num_particles, 3, num_timesteps)
    num_particles = length(index_particles);
    num_timesteps = length(time_vector);
    position_particles = reshape(position_particles, num_particles, 3, num_timesteps);