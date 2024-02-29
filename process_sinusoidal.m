clear all
close all

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Load the data
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

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

% Constants
% dt = 2.27326038544775e-05;
% driving_frequency = 1;

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
dimensionless_p = NaN;

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
    elseif ~isempty(strfind(line, 'dimensionless_p'))
        dimensionless_p_str = line(strfind(line, 'dimensionless_p=')+16:end);
        dimensionless_p = str2double(dimensionless_p_str);
    end
end

% Close the file
fclose(fileID);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Go through each probe and do
% a sinusoidal fit.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
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
            clear 'R';
            clear 'R2';
        end
    catch
        disp(['R^2 value is less than 0.5 for probe ' num2str(probe_number) ', continuing with the next probe.']);
        clear 'R';
        clear 'R2';
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Plot all the probes that had
% met the criteria
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
plot_mult_probe_zdisp(valid_probe_numbers)

% Save the plot as an image file with driving frequency included in the filename
plot_filename = sprintf('mult_probe_zdisp_freq_%s.png', num2str(driving_frequency));
print(plot_filename, '-dpng');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Semi log plot (because exponential)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

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

% Save the plot as an image file with driving frequency included in the filename
plot_filename = sprintf('linear_fit_plot_freq_%s.png', num2str(driving_frequency));
print(plot_filename, '-dpng');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Export driving_frequency, attenuation,kn,kt,gamma_n,gamma_t
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Load existing data from test.txt if it exists
if exist('attenuation_data.txt', 'file') == 2
    existing_data = dlmread('attenuation_data.txt');
else
    existing_data = [];
end

attenuation = abs(slope);
% Append the new data to the existing data
new_data = [driving_frequency, attenuation,kn,kt,gamma_n,gamma_t,dimensionless_p];
combined_data = [existing_data; new_data];

% Write the combined data to test.txt
dlmwrite('attenuation_data.txt', combined_data);