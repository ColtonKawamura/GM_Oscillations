% Load data from test.txt
data = dlmread('attenuation_data.txt', ',');

% Extract columns
frequency = data(:, 1);
attenuation = data(:, 2);

% Plot frequency vs. gamma_n
plot(frequency, attenuation, 'o');
xlabel('Frequency');
ylabel('attenuation');
title('Frequency vs. attenuation');
grid on;