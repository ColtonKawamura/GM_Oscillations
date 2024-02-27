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

    % Constants
    dt = 2.27326038544775e-05;
    time = step * dt;
    initial_amplitude = 0.001;
    initial_phase_offset = 0;
    driving_frequency = 1;

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
end
