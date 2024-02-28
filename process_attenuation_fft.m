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
probe_columns = data(:, 2:end); 

% Create variables for each probe
num_probes = size(probe_columns, 2);

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
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Go through each probe and do
% a sinusoidal fit.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
for probe_number = 1:num_probes
    try
        % Get the specified probe data
        probe_data = real(probe_columns(:, probe_number));
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
        dominant_frequency = freq_vector(idx_max);

        % Find the index of the frequency closest to 1
         desired_frequency = driving_frequency;

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
                [~, idx_closest] = min(abs(freq_vector - desired_frequency));
                % Retrieve the amplitude at the index closest to 1
                closest_frequency = freq_vector(idx_closest)
                closest_amplitude = abs(normalized_fft_data(idx_closest)) * 2
                % If good, store the vector and probe number
                initial_position_vector = [initial_position_vector, probe_data(1)];
                amplitude_vector = [amplitude_vector, closest_amplitude];
                valid_probe_numbers = [valid_probe_numbers, probe_number];
            else
                fprintf('*** Alert: No peak found around the desired frequency. ***\n');
            end
        else
            fprintf('*** Alert: No peak found around the desired frequency. ***\n');
        end
    catch
        dfprintf('*** Alert: No peak found around the desired frequency. ***\n');
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
new_data = [driving_frequency, attenuation,kn,kt,gamma_n,gamma_t];
combined_data = [existing_data; new_data];

% Write the combined data to test.txt
dlmwrite('attenuation_data.txt', combined_data);