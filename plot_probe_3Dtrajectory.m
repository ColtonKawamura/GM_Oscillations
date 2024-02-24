%Argument is the probe number "1 or 2, etc", not probeN
function plot_probe_3Dtrajectory(probe_number)
    % Load x, y, and z data
    x_data = textread('plotdata_probes_xdisp.txt', '', 'headerlines', 1);
    y_data = textread('plotdata_probes_ydisp.txt', '', 'headerlines', 1);
    z_data = textread('plotdata_probes_zdisp.txt', '', 'headerlines', 1);
    
    % Extract columns for the specified probe
    x_position = x_data(:, probe_number + 1);  % Probe 1 data is in the 2nd column
    y_position = y_data(:, probe_number + 1);
    z_position = z_data(:, probe_number + 1);
    step = z_data(:, 1);

    % Plot 3D trajectory
    figure;
    plot3(x_position-x_position(1), y_position-y_position(1), z_position-z_position(1), 'b-', 'LineWidth', 2);
    xlabel('X Position');
    ylabel('Y Position');
    zlabel('Z Position');
    title(['Trajectory of Probe ' num2str(probe_number)],'FontSize', 16);
    grid on;
end


%With color:
% function plot_probe_3Dtrajectory(probe_number)
%     % Load x, y, and z data
%     x_data = textread('plotdata_probes_xdisp.txt', '', 'headerlines', 1);
%     y_data = textread('plotdata_probes_ydisp.txt', '', 'headerlines', 1);
%     z_data = textread('plotdata_probes_zdisp.txt', '', 'headerlines', 1);
    
%     % Extract columns for the specified probe
%     x_position = x_data(:, probe_number + 1);  % Probe 1 data is in the 2nd column
%     y_position = y_data(:, probe_number + 1);
%     z_position = z_data(:, probe_number + 1);
%     step = z_data(:, 1);

%     % Create custom colormap
%     colormap_line = [linspace(0, 0, length(step))' linspace(0, 0, length(step))' linspace(1, 1, length(step))']; % Blue to Red colormap

%     % Plot 3D trajectory
%     figure;
%     for i = 1:length(step)
%         color_index = round((i / length(step)) * size(colormap_line, 1)); % Calculate color index
%         plot3(x_position(1:i)-x_position(1), y_position(1:i)-y_position(1), z_position(1:i)-z_position(1), 'Color', colormap_line(color_index, :), 'LineWidth', 2);
%         hold on;
%     end
    
%     xlabel('X Position');
%     ylabel('Y Position');
%     zlabel('Z Position');
%     title(['Trajectory of Probe ' num2str(probe_number)]);
%     grid on;
%     hold off;
    
%     % Add colorbar
%     c = colorbar;
%     c.Label.String = 'Step';
% end
