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

        % Go through each probe and perform sinusoidal fit
        for probe_number = 1:num_probes
            try
                % Get the specified probe data
                probe_data = real(probe_columns(:, probe_number));

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

                % Calculate correlation coefficient
                [R, ~] = corrcoef(fit_function(s, fit_x), fit_y);
                R2 = R(1, 2)^2;

                % Check if R2 is less than 0.5
                if R2 < 0.5
                    % disp(['R^2 value is less than 0.5 for probe ' num2str(probe_number) ', continuing with the next probe.']);
                else
                    % If good, store the vector and probe number
                    initial_position_vector = [initial_position_vector, probe_data(1)];
                    amplitude_vector = [amplitude_vector, s(1)];
                    phase_vector = [phase_vector, s(2)];
                    valid_probe_numbers = [valid_probe_numbers, probe_number];
                    clear 'R';
                    clear 'R2';
                end
            catch
                % disp(['R^2 value is less than 0.5 for probe ' num2str(probe_number) ', continuing with the next probe.']);
                clear 'R';
                clear 'R2';
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
            title('Linear Fit of Attenuation of Oscillation in Probes', 'FontSize', 16);
            legend('show');
            grid on;


            % Add equation text to the plot
            text_location_x = max(initial_position_vector);
            text_location_y = max(abs(amplitude_vector));
            text(text_location_x, text_location_y, equation_str, 'FontSize', 12, 'Color', 'k');
            hold off;

            % Save the plot as an image file with driving frequency included in the filename
            plot_filename = sprintf('./outputs/linear_fit_plot_pressure_%s_freq_%s.png',num2str(dimensionless_p), num2str(driving_frequency));
            print(plot_filename, '-dpng');

            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % Plot Wavenumber
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % Plot initial position vs. phase as dots
            figure;
            scatter(initial_position_vector, phase_vector, 'o');
            grid on;
            hold on;  % Keep the plot for adding the fitted line

            % Fit a line to the data
            p = polyfit(initial_position_vector, phase_vector, 1);
            fitted_line = polyval(p, initial_position_vector);

            % Plot the fitted line
            plot(initial_position_vector, fitted_line, '-r');

            % Store the slope of the line as wavenumber
            wavenumber = p(1);
            wavespeed = driving_frequency/wavenumber;

            % Label the axes
            xlabel('x(t=0)');
            ylabel('\Delta\phi');

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
