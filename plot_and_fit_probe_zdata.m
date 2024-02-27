function plot_and_fit_probe_zdata(probe_number)

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
    dt = 1e-05;
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
    [R, ~] = corrcoef(fit_function(s, fit_x), fit_y);
    R2 = R^2;

    % Define the model function using the fitted parameters
    model_function = @(b, X) b(1) .* sin(2 * pi * driving_frequency * X - b(2));

    % Generate model predictions using the fitted parameters
    fitted_data = model_function(s, fit_x);

    % Define the equation of the fitted curve
    equation = sprintf('y = %.4f * sin(2*pi*%.4f * x - %.4f)', s(1), driving_frequency, s(2));

    %Save the Amplitude as a variable
    probe_amplitude = s(1);

    % Plot original data and fitted data
    figure;
    plot(fit_x, fit_y, 'b.', 'DisplayName', 'Original Data'); % Plot original data as blue dots
    hold on;
    plot(fit_x, fitted_data, 'r-', 'DisplayName', 'Fitted Data'); % Plot fitted data as a red line

    % Add equation text to the legend
    legend('show'); % Show legend
    legend('Original Data', 'Fitted Data'); % Add legend entries
    text_location_x = min(fit_x) + 0.2 * range(fit_x); % Adjust text x-location
    text_location_y = max(fit_y) + 0.05 * range(fit_y); % Adjust text y-location
    text(text_location_x, text_location_y, equation, 'FontSize', 12, 'Color', 'k', 'Interpreter', 'latex'); % Add equation text

    xlabel('Time'); % Label x-axis
    ylabel('Probe Data'); % Label y-axis
    title('Fitted Data vs. Original Data'); % Add title
    hold off;
end
