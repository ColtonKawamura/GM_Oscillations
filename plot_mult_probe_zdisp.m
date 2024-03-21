function plot_mult_probe_zdisp(filename, varargin)
    % Load data
    data = textread(filename, '', 'headerlines', 1);
    
    % Extract columns
    step = data(:, 1);
    probe_columns = data(:, 2:end);
    
    % Determine number of probes
    num_probes = size(probe_columns, 2);
    
    % Initialize plot
    figure;
    
    % Plot trajectories for each specified probe
    for i = 1:numel(varargin)
        % Determine the column for the current probe
        probe_index = varargin{i};
        
        % Subtract the initial value from each point
        probe_data = probe_columns(:, probe_index) - probe_columns(1, probe_index);
        
        % Plot the selected column
        plot(step, probe_data);
        
        % Hold the plot
        hold on;
    end
    
    % Customize labels and title
    xlabel('Step');
    ylabel('Displacement');
    title('Z-Trajectories of Selected Probes', 'FontSize', 16);
    legend(cellstr(num2str([varargin{:}]')), 'Location', 'best');
    grid on;
    
    % Release hold
    hold off;
end
