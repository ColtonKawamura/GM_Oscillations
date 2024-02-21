clear all
close all
% figure
% % Load the data without the header (Octave specific)
data = textread('plotdata_probes_zdisp.txt', '', 'headerlines', 1);

% Extract columns
step = data(:, 1);
probe_columns = data(:, 2:end);


% figure;
% plot(step, probe_columns);
% % legend('Probe1', 'Probe2');
% xlabel('Step');
% ylabel('z-Position');
% title('All Probe z-Position During Simulation','fontsize', 16);
% grid on;

% Create variables for each probe
num_probes = size(probe_columns, 2);

for i = 1:num_probes
    variable_name = ['probe' num2str(i)];
    eval([variable_name ' = probe_columns(:, i);']);
end

% Define the specific probes to plot
probes_to_plot = [1, 2, 3, 4, 5,6,7,8,9];

% Plot selected probes in a subplot in reverse order
figure;

for i = length(probes_to_plot):-1:1
    subplot(length(probes_to_plot), 1, length(probes_to_plot) - i + 1);  % Adjust the subplot index
    
    % Determine the column for the current probe
    probe_index = probes_to_plot(i);
    
    % Plot the selected column
    plot(step, probe_columns(:, probe_index));
    
    % Customize labels and title
    xlabel('Step');
    % ylabel(['z-Position']);
    title(['Probe' num2str(probe_index)]);
    grid on;
end

% Define the specific probes to plot
probes_to_plot = [10, 20, 40, 80, 160];

% Plot selected probes in a subplot in reverse order
figure;

for i = length(probes_to_plot):-1:1
    subplot(length(probes_to_plot), 1, length(probes_to_plot) - i + 1);  % Adjust the subplot index
    
    % Determine the column for the current probe
    probe_index = probes_to_plot(i);
    
    % Plot the selected column
    plot(step, probe_columns(:, probe_index));
    
    % Customize labels and title
    xlabel('Step');
    % ylabel(['z-Position']);
    title(['Probe' num2str(probe_index)]);
    grid on;
end

%%%%% Create x0, a single vector of all initial positions of all probes %%%%

% Initialize N to 0
N = 0;

% Loop through potential probe variable names until one is not found
while true
    % Construct the next potential probe variable name
    probe_name = ['probe', num2str(N + 1)];
    
    % Check if the variable exists in the workspace
    if ~exist(probe_name, 'var')
        % Exit the loop if the variable is not found
        break;
    end
    
    % Increment N
    N = N + 1;
end

% Initialize x0 vector
x0 = zeros(1, N);

% Loop through each probe's position vector and extract the first element
for i = 1:N
    % Construct the name of the ith probe variable
    probe_name = ['probe', num2str(i)];
    
    % Retrieve the corresponding probe vector
    probe_vector = eval(probe_name);
    
    % Extract the first element from the probe vector and store it in x0
    x0(i) = probe_vector(1);
end

%%% Create x_all, a matrix of all positions of all probes over time %%%
% Initialize a cell array to store probe vectors
probe_vectors = cell(1, N);

% Loop through each probe's position vector and store it in the cell array
for i = 1:N
    % Construct the name of the ith probe variable
    probe_name = ['probe', num2str(i)];
    
    % Retrieve the corresponding probe vector
    probe_vector = eval(probe_name);
    
    % Store the probe vector in the cell array
    probe_vectors{i} = probe_vector;
end

%%%%%%%%%%%%%%%%%%%%
dt = 8.53793823217796e-06;
time = step*dt;
initial_amplitude = .001;
initial_phase_offset = 0;
driving_frequency = 1;

index_initial_oscillation = find(probe5>probe5(1)+0.5*(max(probe5)-probe5(1)),1,'first')
fit_x = time(index_initial_oscillation:end);
fit_y = probe5(index_initial_oscillation:end)-probe5(1);


fit = @(b, X) b(1) .* sin(2*pi*driving_frequency * X - b(2)); % Function to fit
fcn = @(b) sum((fit(b, fit_x) - fit_y).^2); % Least-Squares cost function
initial_guess = [initial_amplitude; initial_phase_offset];
[s, fval, exitflag] = fminsearch(fcn, initial_guess);
[R, P] = corrcoef(fit(s, fit_x), fit_y);
R2 = R.^2;

% Define your model function using the fitted parameters
model_function = @(b, X) b(1) .* sin(2*pi*driving_frequency  * X - b(2));

% Generate model predictions using the fitted parameters
fitted_data = model_function(s, fit_x);

% Plot original data and fitted data
figure;
plot(fit_x, fit_y, 'b.', 'DisplayName', 'Original Data'); % Plot original data as blue dots
hold on;
plot(fit_x, fitted_data, 'r-', 'DisplayName', 'Fitted Data'); % Plot fitted data as a red line
xlabel('Time'); % Label x-axis
ylabel('Probe 5'); % Label y-axis
title('Fitted Data vs. Original Data'); % Add title
legend('show'); % Show legend
hold off;