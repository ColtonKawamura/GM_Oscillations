function attenuation_z_probe(probe_number)

    %Initialize output vectors
    inital_position_vector = [];
    amplitude_vector = [];

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

    % Find initial oscillation index
    index_initial_oscillation = find(probe_data > probe_data(1) + 0.5 * (max(probe_data) - probe_data(1)), 1, 'first');

    % Prepare data for fitting
    fit_x = time(index_initial_oscillation:end);
    fit_y = probe_data(index_initial_oscillation:end) - probe_data(1);

    % Define function to fit
    fit_function = @(b, X) b(1) .* sin(2 * pi * driving_frequency * X - b(2));
    
    % Define least-squares cost function
    cost_function = @(b) sum((fit_function(b, fit_x) - fit_y).^2);

    % Initial guess
    initial_guess = [initial_amplitude; initial_phase_offset];

    % Perform fitting
    [s, ~, ~] = fminsearch(cost_function, initial_guess);

    % Calculate correlation coefficient
    [R, P] = corrcoef(fit_function(s, fit_x), fit_y)
    R2 = R.*R

    % Check if R2 is less than 0.5
    if R2(1,2) < 0.5
        disp(['R^2 value is less than 0.5 for probe ' num2str(probe_number) ', stopping further processing.']);
        return; % Exit the loop and function
    end

    %If good, store the vector
    inital_position_vector = [inital_position_vector, probe_data(1)];
    amplitude_vector = [amplitude_vector, s(1)];
end
