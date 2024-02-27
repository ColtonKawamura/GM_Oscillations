clear all
close all

% Initialize output vectors
initial_position_vector = [];
amplitude_vector = [];
valid_probe_numbers = [];

% Load the data without the header (Octave specific)
data = textread('plotdata_probes_zdisp.txt', '', 'headerlines', 1);

% Extract columns
step = data(:, 1);
probe_columns = data(:, 2:end); %changed this from the 2nd column to 3rd because 1st probe breaks corrcoef and is a bottomwall group

% Create variables for each probe
num_probes = size(probe_columns, 2);

% Import constants
% Open the file for reading
fileID = fopen('meta_data.txt', 'r');

% Initialize variables
dt = '';
frequency = '';
kn = '';
kt = '';
gamma_n = '';
gamma_t = '';

% Read the file line by line
while ~feof(fileID)
    line = fgetl(fileID);
    % Find and extract parameters
    if ~isempty(strfind(line, 'dt='))
        dt = line(strfind(line, 'dt=')+3:end);
    elseif ~isempty(strfind(line, 'frequency='))
        driving_frequency = line(strfind(line, 'frequency=')+10:end);
    elseif ~isempty(strfind(line, 'kn='))
        kn = line(strfind(line, 'kn=')+3:end);
    elseif ~isempty(strfind(line, 'kt='))
        kt = line(strfind(line, 'kt=')+3:end);
    elseif ~isempty(strfind(line, 'gamma_n='))
        gamma_n = line(strfind(line, 'gamma_n=')+8:end);
    elseif ~isempty(strfind(line, 'gamma_t='))
        gamma_t = line(strfind(line, 'gamma_t=')+8:end);
    end
end

% Close the file
fclose(fileID);


for probe_number = 1:num_probes
    try
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
            disp(['R^2 value is less than 0.5 for probe ' num2str(probe_number) ', continuing with the next probe.']);
        else
            % If good, store the vector and probe number
            initial_position_vector = [initial_position_vector, probe_data(1)];
            amplitude_vector = [amplitude_vector, s(1)];
            valid_probe_numbers = [valid_probe_numbers, probe_number];
        end
    catch
        disp(['R^2 value is less than 0.5 for probe ' num2str(probe_number) ', continuing with the next probe.']);
    end
end

%Regular Plot
% figure;
% plot(initial_position_vector, abs(amplitude_vector), 'bo')
% xlabel('Distance');
% ylabel('Probe Oscillation Amplitude');
% title('Attenuation of Oscillation in Probes', 'FontSize', 16);
% legend(cellstr(num2str(valid_probe_numbers')), 'Location', 'best'); % Use valid probe numbers for legend entries
% grid on;

plot_mult_probe_zdisp(valid_probe_numbers)


% %%%Loglog Plot
% figure;
% loglog(initial_position_vector, abs(amplitude_vector), 'bo')
% xlabel('Distance');
% ylabel('Probe Oscillation Amplitude');
% title('Attenuation of Oscillation in Probes', 'FontSize', 16);
% legend(cellstr(num2str(valid_probe_numbers')), 'Location', 'best'); % Use valid probe numbers for legend entries
% grid on;

% Perform linear fit
coefficients = polyfit(initial_position_vector, log(abs(amplitude_vector)), 1);

% Extract slope and intercept
slope = coefficients(1);
intercept = coefficients(2);

% Create a linear fit line
fit_line = exp(intercept) * exp(initial_position_vector.*slope);

% Convert coefficients to string
equation_str = sprintf('y = %.4f * exp(%.4f)', exp(intercept), slope);

% Plot original data and linear fit
figure;
semilogy(initial_position_vector, abs(amplitude_vector), 'bo', 'DisplayName', 'Data');
hold on;
semilogy(initial_position_vector, fit_line, 'r-', 'DisplayName', 'Linear Fit');
xlabel('Distance');
ylabel('Probe Oscillation Amplitude');
title('Linear Fit of Attenuation of Oscillation in Probes', 'FontSize', 16);
legend('show');
grid on;


% Add equation text to the plot
text_location_x = max(initial_position_vector);
text_location_y = max(abs(amplitude_vector));
text(text_location_x, text_location_y, equation_str, 'FontSize', 12, 'Color', 'k');
hold off;