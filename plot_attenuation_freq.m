% Load data from test.txt
data = dlmread('attenuation_data.txt', ',');

% Extract columns
frequency = data(:, 1);
attenuation = data(:, 2);
kn = data(:, 3);
kt = data(:, 4);
gamma_n = data(:, 5);
gamma_t = data(:, 6);

% Calculate angular frequency
angular_frequency = 2 * pi * frequency;

% Calculate the product of angular frequency and gamma_n
angular_freq_times_gamma_n = angular_frequency .* gamma_n;

% Plot the log-log plot
loglog(angular_freq_times_gamma_n, attenuation, 'o');
xlabel('\omega \times \Gamma_n');
ylabel('Attenuation');
title('Attenuation Results');
grid on;