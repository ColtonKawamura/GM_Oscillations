probe_number= 335       
                
                
                % Get the specified probe data
                probe_data = real(probe_columns(:, probe_number));

                % Perform fft on the current probe

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

                % Find the index of the frequency closest to driving frequency
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
                        % fprintf('Peak found around the driving frequency. Performing sinusoidal fit for phase\n');

                        % Find initial oscillation index when displacement rise above 1/2 max displacement
                        index_initial_oscillation = find(probe_data > probe_data(1) + 0.5 * (max(probe_data) - probe_data(1)), 1, 'first');
                        % Prepare data for fitting
                        fit_x = step(index_initial_oscillation:end) * dt;
                        fit_y = probe_data(index_initial_oscillation:end) - probe_data(1);

                        % Define function to fit
                        fit_function = @(b, X) b(1) .* sin(2 * pi * driving_frequency * X - b(2));

                        % Define least-squares cost function
                        cost_function = @(b) sum((fit_function(b, fit_x) - fit_y).^2);

                        % Initial guess
                        initial_amplitude =  driving_amplitude;
                        initial_guess = [initial_amplitude; initial_phase_offset];

                        % Perform fitting
                        [s, ~, ~] = fminsearch(cost_function, initial_guess);

                        % Update the initial phase offset for the next iteration
                        initial_phase_offset = s(2);
                        amplitude_vector = [amplitude_vector, amplitude]; % Pulls amplitude from fft calculation
                        initial_position_vector = [initial_position_vector, probe_data(1)];
                        phase_vector = [phase_vector, angle(normalized_fft_data(idx_desired))];
                        % phase_vector = [phase_vector, s(2)];
                        valid_probe_numbers = [valid_probe_numbers, probe_number];
                    else
                        % fprintf('*** Alert: No peak found around the driving frequency. ***\n');
                    end
                else
                    % fprintf('*** Alert: No peak found around the driving frequency. ***\n');
                end


figure; % Create a new figure window
stem(freq_vector, abs(normalized_fft_data(index_vector)) * 2); % Plot the frequency spectrum
xlabel('Frequency (Hz)'); % Label the x-axis
ylabel('Amplitude'); % Label the y-axis
title('Frequency Spectrum'); % Title for the plot
grid on; % Turn on the grid for easier visualization

% Calculate the maximum frequency to be shown on the x-axis
max_frequency = max(freq_vector);

% Set x-axis tick marks in increments of 1 Hz
xticks(0:1:max_frequency);

% Optionally, if the plot is dense, you may want to limit the number of ticks shown
% For example, to show every 5 Hz, you could use:
% xticks(0:5:max_frequency);

