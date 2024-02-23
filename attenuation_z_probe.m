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

% Constants
dt = 2.27326038544775e-05;
driving_frequency = 1;

for probe_number = 1:num_probes
    % Get the specified probe data
    probe_data = real(probe_columns(:, probe_number));

    % Find initial oscillation index
    index_initial_oscillation = find(probe_data > probe_data(1) + 0.5 * (max(probe_data) - probe_data(1)), 1, 'first');

    % Prepare data for fitting
    fit_x = step(index_initial_oscillation:end) * dt;
    fit_y = probe_data(index_initial_oscillation:end) - probe_data(1);

    % Define function to fit
    fit_function = @(b, X) b(1) .* sin(2 * pi * driving_frequency * X - b(2));
    
    % Define least-squares cost function
    cost_function = @(b) sum((fit_function(b, fit_x) - fit_y).^2);

    % Initial guess
    initial_amplitude = 0.001;
    initial_phase_offset = 0;
    initial_guess = [initial_amplitude; initial_phase_offset];

    % Perform fitting
    [s, ~, ~] = fminsearch(cost_function, initial_guess);

    % Calculate correlation coefficient
    [R, ~] = corrcoef(fit_function(s, fit_x), fit_y);
    R2 = R(1, 2)^2;

    % Check if R2 is less than 0.5
    if R2 < 0.5
        disp(['R^2 value is less than 0.5 for probe ' num2str(probe_number) ', stopping further processing.']);
    else
        % If good, store the vector
        inital_position_vector = [inital_position_vector, probe_data(1)];
        amplitude_vector = [amplitude_vector, s(1)];
    end
end

% Display or further process the vectors as needed
disp('Initial position vector:');
disp(inital_position_vector);
disp('Amplitude vector:');
disp(amplitude_vector);
