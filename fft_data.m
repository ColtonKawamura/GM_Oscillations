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
    Clm = probe_data-mean(probe_data);                                  % Subtract Mean (Mean = 0 Hz)
    FCl = fft(Clm)/number_elements_time;
    Fv = linspace(0, 1, fix(number_elements_time/2)+1)*Fn;
    Iv = 1:numel(Fv);

    [max_val, idx_max] = max(abs(FCl(Iv)) * 2)
    corresponding_frequency = Fv(idx_max)
end
