clear all
close all

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
    variable_name = ['zprobe' num2str(i)];
    eval([variable_name ' = probe_columns(:, i);']);
end

% % Load the data without the header (Octave specific)
data = textread('plotdata_probes_xdisp.txt', '', 'headerlines', 1);

% Extract columns
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
    variable_name = ['xprobe' num2str(i)];
    eval([variable_name ' = probe_columns(:, i);']);
end

% % Load the data without the header (Octave specific)
data = textread('plotdata_probes_ydisp.txt', '', 'headerlines', 1);

% Extract columns
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
    variable_name = ['yprobe' num2str(i)];
    eval([variable_name ' = probe_columns(:, i);']);
end

% Plot 3D trajectory with animation
figure;
for i = 1:length(step)
    plot3(xprobe2(1:i), yprobe2(1:i), zprobe2(1:i), 'b-', 'LineWidth', 2);
    xlabel('X');
    ylabel('Y');
    zlabel('Z');
    title(sprintf('3D Trajectory of Probe at t = %.2f', step(i)));
    grid on;
    drawnow; % Force plot to update
end

% Plot 3D trajectory
figure;
plot3(xprobe2, yprobe2, zprobe2, 'b-', 'LineWidth', 2);
xlabel('X');
ylabel('Y');
zlabel('Z');
title('3D Trajectory of Probe');
grid on;

% Plot 3D trajectory of probe2
figure;
plot3(xprobe5, yprobe5, zprobe5, 'b-', 'LineWidth', 2);
xlabel('X');
ylabel('Y');
zlabel('Z');
title('3D Trajectory of Probe2');
grid on;

% Calculate the range of motion in the x and y directions
x_range = max(xprobe5) - min(xprobe5);
y_range = max(yprobe5) - min(yprobe5);

% Set x and y limits to be the maximum range of motion
xlim([min(xprobe5), min(xprobe5) + x_range]);
ylim([min(yprobe5), min(yprobe5) + y_range]);

% Plot 3D trajectory
figure;
plot3(xprobe40, yprobe40, zprobe40, 'b-', 'LineWidth', 2);
xlabel('X');
ylabel('Y');
zlabel('Z');
title('3D Trajectory of Probe');
grid on;

% Plot 3D trajectory of probe2
figure;
plot3(xprobe40, yprobe40, zprobe40, 'b-', 'LineWidth', 2);
xlabel('X');
ylabel('Y');
zlabel('Z');
title('3D Trajectory of Probe40');
grid on;

% Calculate the range of motion in the x and y directions
x_range = max(xprobe40) - min(xprobe40);
y_range = max(yprobe40) - min(yprobe40);

% Set x and y limits to be the maximum range of motion
xlim([min(xprobe40), min(xprobe40) + x_range]);
ylim([min(yprobe40), min(yprobe40) + y_range]);