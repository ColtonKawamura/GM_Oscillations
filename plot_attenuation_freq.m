%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Purpose of this is to make a sinusoidal fit to the data output
% from attenuation_data.txt and perform a linear fit
% to loglog data.
% 
% Output are plot of the data and creation of output data for future
% processing.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Load data from test.txt
data = dlmread('attenuation_data.txt', ',');

% Extract columns
frequency = data(:, 1);
attenuation = data(:, 2);
kn = data(:, 3);
kt = data(:, 4);
gamma_n = data(:, 5);
gamma_t = data(:, 6);
dimensionless_p = data(:, 7);

% Calculate angular frequency
angular_frequency = 2 * pi * frequency;

% Calculate the product of angular frequency and gamma_n
angular_freq_times_gamma_n = angular_frequency .* gamma_n;

% Perform linear fit
coefficients = polyfit(log(angular_freq_times_gamma_n), log(attenuation), 1);

% Extract slope and intercept
slope = coefficients(1);
intercept = coefficients(2);

% Create a linear fit line
fit_line = exp(intercept) * exp(log(angular_freq_times_gamma_n) * slope);

% Convert coefficients to string
equation_str = sprintf('y = %.4f * x + %.4f', slope, intercept);

% Plot original data and linear fit
figure;
loglog(angular_freq_times_gamma_n, attenuation, 'bo', 'DisplayName', 'Data');
hold on;
loglog(angular_freq_times_gamma_n, fit_line, 'r-', 'DisplayName', 'Linear Fit');
xlabel('\omega \gamma_n');
ylabel('Attenuation');
title('Linear Fit of Attenuation vs. \omega \gamma_n', 'FontSize', 16);
legend('show');
grid on;

% Add equation text to the plot
text_location_x = max(angular_freq_times_gamma_n);
text_location_y = min(attenuation);
text(text_location_x/10, text_location_y*10, equation_str, 'FontSize', 12, 'Color', 'k');
hold off;

% Save data to text file
data_filename = sprintf('data_attenuation_pressure_%.8f_freq_%.8f.txt', dimensionless_p, frequency);
dlmwrite(data_filename, [frequency, attenuation, kn, kt, gamma_n, gamma_t, dimensionless_p], ',');

% Save plot as PNG file
plot_filename = sprintf('plot_attenuation_pressure_%.8f_freq_%.8f.png', dimensionless_p, frequency);
saveas(gcf, plot_filename);