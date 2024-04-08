% Specify the directory containing the data files
outputs_directory = './outputs/';

% Define a regular expression pattern to extract the values from the file name
pattern = 'plotdata_probes_zdisp\.(\w+)\.pressure_([\d.]+)\.freq_([\d.]+)\.amp_([\d.]+)\.txt';

% Use dir to find all data files in the outputs directory after concatenating outputs_directory with 'whatever file'
data_files_info = dir(fullfile(outputs_directory, 'plotdata_probes_zdisp.*.txt'));

% Initialize output vectors
initial_position_vector = [];
amplitude_vector = [];
phase_vector = [];
valid_probe_numbers = [];
initial_phase_offset = 0;

% Loop through each data file found
for i = 1:numel(data_files_info)
    % Get the file name
    data_file = data_files_info(i).name;
    
    % Construct the full file path
    data_file_path = fullfile(outputs_directory, data_file);
    
    % Extract the values from the file name using regular expressions
    match = regexp(data_file, pattern, 'tokens', 'once');
    
    % Display the extracted values
    if ~isempty(match)
        friction_status = match{1};
        pressure = str2double(match{2});
        frequency = str2double(match{3});
        amplitude = str2double(match{4});
        
        fprintf('Processing data file: %s\n', data_file_path);
        
        % Perform data processing and sinusoidal fitting here
        % Use the extracted parameters (friction_status, pressure, frequency, amplitude)
        % to load and process the corresponding data file
        
        % Load the data without the header
        data = textread(data_file_path, '', 'headerlines', 1);
        
        % Extract columns
        step = data(:, 1);
        probe_columns = data(:, 2:end);
        
        % Create variables for each probe
        num_probes = size(probe_columns, 2);

        % Pull parameter data from the simulation (if necessary)
       % Construct the meta_data file name dynamically
        metafilename = sprintf('./outputs/meta_data.%s.pressure_%g.freq_%g.amp_%g.txt', friction_status, pressure, frequency, amplitude);
        
        % Open the meta_data file for reading
        fileID = fopen(metafilename, 'r');
        
        % Check if the file exists
        if fileID == -1
            fprintf('Meta data file %s not found.\n', metafilename);
            continue;  % Skip processing this data file
        end

        dt = NaN;
        driving_frequency = NaN;
        kn = NaN;
        kt = NaN;
        gamma_n = NaN;
        gamma_t = NaN;
        dimensionless_p = NaN;
        driving_amplitude = NaN;

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
            elseif ~isempty(strfind(line, 'driving_amplitude'))
                driving_amplitude_str = line(strfind(line, 'driving_amplitude=')+18:end);
                driving_amplitude = str2double(driving_amplitude_str);
            end
        end

        % Close the file
        fclose(fileID);
        time = step * dt;

        % Go through each probe and perform sinusoidal fit
        for probe_number = 1:num_probes
            try
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
                        fprintf('Peak found around the driving frequency. Performing sinusoidal fit for phase\n');

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
                        phase_vector = [phase_vector, s(2)];
                        valid_probe_numbers = [valid_probe_numbers, probe_number];
                    else
                        fprintf('*** Alert: No peak found around the driving frequency. ***\n');
                    end
                else
                    fprintf('*** Alert: No peak found around the driving frequency. ***\n');
                end
            catch
            end
        end

            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % Plot all the probes that had
            % met the criteria
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            plot_mult_probe_zdisp(data_file_path, valid_probe_numbers)

            % Save the plot as an image file with driving frequency included in the filename
            plot_filename = sprintf('./outputs/mult_probe_zdisp_pressure_%s_freq_%s.png', num2str(dimensionless_p), num2str(driving_frequency));
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
            % title('Linear Fit of Attenuation of Oscillation in Probes', 'FontSize', 16);
                % Set the title with variables
            title(sprintf('f=%.2f, k_n=%.2f, gamma_n=%.2f, P=%.2f, alpha=%.2f', driving_frequency, kn, gamma_n, dimensionless_p, slope), 'FontSize', 12);
            legend('show');
            grid on;

            hold off;

            % Save the plot as an image file with driving frequency included in the filename
            plot_filename = sprintf('./outputs/linear_fit_plot_pressure_%s_freq_%s.png',num2str(dimensionless_p), num2str(driving_frequency));
            print(plot_filename, '-dpng');

            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % Plot Wavenumber
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            unwrapped_phase_vector = unwrap(phase_vector);

            % Plot initial position vs. phase as dots
            figure;
            scatter(initial_position_vector, unwrapped_phase_vector, 'o');
            grid on;
            hold on;  % Keep the plot for adding the fitted line

            % Fit a line to the data
            p = polyfit(initial_position_vector, unwrapped_phase_vector, 1);
            fitted_line = polyval(p, initial_position_vector);

            % Plot the fitted line
            plot(initial_position_vector, fitted_line, '-r');

            % Store the slope of the line as wavenumber
            wavenumber = p(1);
            wavespeed = driving_frequency/wavenumber;

            % Label the axes
            xlabel('z(t=0)');
            ylabel('\Delta\phi');

            % Customizing y-axis to show multiples of pi
            y_max = max(unwrapped_phase_vector);  % Get the maximum y value
            y_min = min(unwrapped_phase_vector);  % Get the minimum y value
            yticks = [ceil(y_min/pi)*pi:pi:floor(y_max/pi)*pi];  % Define y-ticks in steps of pi
            yticklabels = arrayfun(@(x) sprintf('%.2f\\pi', x/pi), yticks, 'UniformOutput', false);  % Create custom y-tick labels
            set(gca, 'YTick', yticks, 'YTickLabel', yticklabels);  % Apply custom ticks and labels

            % Set the title with variables
            title(sprintf('f=%.2f, k_n=%.2f, gamma_n=%.2f, P=%.2f, k=%.2f', driving_frequency, kn, gamma_n, dimensionless_p, wavenumber), 'FontSize', 12);

            % Hold off to finish the plotting
            hold off;

            plot_filename = sprintf('./outputs/wavenumber_plot_pressure_%s_freq_%s.png',num2str(dimensionless_p), num2str(driving_frequency));
            print(plot_filename, '-dpng');

            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % Export driving_frequency, attenuation, kn, kt, gamma_n, gamma_t
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % Construct the filename for the attenuation data dynamically
            attenuation_filename = sprintf('./outputs/attenuation_data_%s_pressure_%g_freq_%g.txt', friction_status, dimensionless_p, driving_frequency);

            % Load existing data from the attenuation file if it exists
            if exist(attenuation_filename, 'file') == 2
                existing_data = dlmread(attenuation_filename);
            else
                existing_data = [];
            end

            attenuation = abs(slope);

            % Append the new data to the existing data
            new_data = [driving_frequency, attenuation, kn, kt, gamma_n, gamma_t, dimensionless_p, driving_amplitude, wavenumber, wavespeed];
            combined_data = [existing_data; new_data];

            % Write the combined data to the attenuation file
            dlmwrite(attenuation_filename, combined_data);
    else
        fprintf('No match found for file: %s\n', data_file_path);
    end
end
