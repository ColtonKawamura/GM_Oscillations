function fft_data(probe_number)

    % Load the data without the header (Octave specific)
    data = textread('plotdata_probes_zdisp.txt', '', 'headerlines', 1);

    % Extract columns
    step = data(:, 1);
    probe_columns = data(:, 2:end);

    % Create variables for each probe
    num_probes = size(probe_columns, 2);

    for i = 1:num_probes
        variable_name = ['probe' num2str(i)];
        eval([variable_name ' = real(probe_columns(:, i));']); % Convert to real numbers
    end

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Pull parameter data from the simulation
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Open the file for reading
    fileID = fopen('meta_data.txt', 'r');

    dt = NaN;
    driving_frequency = NaN;
    kn = NaN;
    kt = NaN;
    gamma_n = NaN;
    gamma_t = NaN;

    % Read the file line by line
    while ~feof(fileID)
        line = fgetl(fileID);
        % Find and extract parameters
        if ~isempty(strfind(line, 'dt='))
            dt_str = line(strfind(line, 'dt=')+3:end);
            dt = str2double(dt_str);
        elseif ~isempty(strfind(line, 'frequency='))
            frequency_str = line(strfind(line, 'frequency=')+10:end);
            driving_frequency = str2double(frequency_str);
        elseif ~isempty(strfind(line, 'kn='))
            kn_str = line(strfind(line, 'kn=')+3:end);
            kn = str2double(kn_str);
        elseif ~isempty(strfind(line, 'kt='))
            kt_str = line(strfind(line, 'kt=')+3:end);
            kt = str2double(kt_str);
        elseif ~isempty(strfind(line, 'gamma_n='))
            gamma_n_str = line(strfind(line, 'gamma_n=')+8:end);
            gamma_n = str2double(gamma_n_str);
        elseif ~isempty(strfind(line, 'gamma_t='))
            gamma_t_str = line(strfind(line, 'gamma_t=')+8:end);
            gamma_t = str2double(gamma_t_str);
        end
    end

    % Close the file
    fclose(fileID);
    time = step * dt;

    % Get the specified probe data
    probe_data = eval(['probe' num2str(probe_number)]);

    probe_data = probe_data;
    average_dt = mean(diff(time));
    sampling_freq = 1/average_dt;
    Fn = sampling_freq/2; % Nyquist frequency 
    number_elements_time = numel(time);
    centered_data = probe_data-mean(probe_data); %Center the data on zero for mean
    normalized_fft_data = fft(centered_data)/number_elements_time; 
    freq_vector = linspace(0, 1, fix(number_elements_time/2)+1)*Fn;
    index_vector = 1:numel(freq_vector);

    % Find the dominant frequency and its amplitude
    %   Need to double it because when signal is centered, power is
    %   distributed in both positive and negative. double the abs accounts for this
    [amplitude, idx_max] = max(abs(normalized_fft_data(index_vector)) * 2);
    dominant_frequency = freq_vector(idx_max)
    amplitude

    % Find the index of the frequency closest to 1
    desired_frequency = 1;

    % Find the index of the closest frequency to the desired frequency
    [~, idx_desired] = min(abs(freq_vector - desired_frequency));

    % Check if there is a peak around the desired frequency
    if idx_desired > 1 && idx_desired < numel(freq_vector)
        % Calculate the sign of the slope before and after the desired frequency
        sign_slope_before = sign(normalized_fft_data(idx_desired) - normalized_fft_data(idx_desired - 1));
        sign_slope_after = sign(normalized_fft_data(idx_desired + 1) - normalized_fft_data(idx_desired));
        
        % Check if the signs of the slopes are different and if the values on both sides are greater than the value at the desired frequency
        if sign_slope_before ~= sign_slope_after && normalized_fft_data(idx_desired - 1) < normalized_fft_data(idx_desired) && normalized_fft_data(idx_desired + 1) < normalized_fft_data(idx_desired)
            fprintf('Peak found around the desired frequency.\n');
        else
            fprintf('*** Alert: No peak found around the desired frequency. ***\n');
        end
    else
        fprintf('*** Alert: No peak found around the desired frequency. ***\n');
    end



    [~, idx_closest] = min(abs(freq_vector - desired_frequency));

    % Retrieve the amplitude at the index closest to 1
    closest_frequency = freq_vector(idx_closest)
    closest_amplitude = abs(normalized_fft_data(idx_closest)) * 2

    figure
    plot(freq_vector, abs(normalized_fft_data(index_vector)) * 2)
    grid
    % Find the width of the peak
    half_width = (closest_frequency - dominant_frequency) / 2;

    % Set xlim to show both sides of the peak
    xlim([dominant_frequency - half_width, closest_frequency + half_width])

end
