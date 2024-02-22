function plot_probe_3Dtrajectory(probe_number)
    % Load x, y, and z data
    x_data = textread('plotdata_probes_xdisp.txt', '', 'headerlines', 1);
    y_data = textread('plotdata_probes_ydisp.txt', '', 'headerlines', 1);
    z_data = textread('plotdata_probes_zdisp.txt', '', 'headerlines', 1);
    
    % Extract columns for the specified probe
    x_position = x_data(:, probe_number + 1);  % Probe 1 data is in the 2nd column
    y_position = y_data(:, probe_number + 1);
    z_position = z_data(:, probe_number + 1);

    % Plot 3D trajectory
    figure;
    plot3(x_position, y_position, z_position, 'b-', 'LineWidth', 2);
    xlabel('X Position');
    ylabel('Y Position');
    zlabel('Z Position');
    title(['Trajectory of Probe ' num2str(probe_number)]);
    grid on;
end
