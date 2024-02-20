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

% Convert the cell array to a matrix with each column representing a probe vector
x_all = cell2mat(probe_vectors)

dt = 8.53793823217796e-06;
left_wall_list = probe1;
tvec = step*dt; %Creates a time vector. 
omega_D = 2*pi*1; %2 pi f
[~,isort] = sort(x0); %sorts the elements of the vector x0 in ascending order and saves the original indices of the sorted elements into the variable isort
iskip = 1;
list = [];
b_start = 0;
offset_guess = 0;

for nn = isort(1:iskip:end) %iterates through a subset of indices from isort, starting from the first index and incrementing by iskip each time.
    if(~left_wall_list(nn)) %checks if left_wall_list(nn) is false
        x_temp = x_all(nn,:); %extracts all elements nn row from the matrix x_all and assigns it to to x_temp

        if length(unique(x_temp))>100 %checks if the number of unique elements in the vector x_temp is greater than 100

            i0 = find(x_temp>x0(nn)+0.5*(max(x_temp)-x0(nn)),1,'first'); %Gets the first occurence when x rises to .5 max amp
            X = tvec(i0:end); %Shaves off elements of tvec that occur before x_temp rising to .5 of max value
            Y = x_temp(i0:end)-x0(nn); %Y = displacement of x
            yu = max(Y(round(end/2):end)); %Max value in the second half of Y
            yl = min(Y(round(end/2):end)); %Min value in the second half of Y
            yr = (yu-yl);                               % Range of ‘y’
            yz = Y-yu+(yr/2); %Centers the data around zero after the max value subtracted
            zx = X(yz .* circshift(yz,[0 1]) <= 0);     % Find zero-crossings
            per = 2*mean(diff(zx));                     % Estimate period
            w_guess = 2*pi/per;
            ym = mean(Y((round(end/2):end)));                              % Estimate offset
            fit = @(b,X)  b(1).*(sin(w_D*X - b(2)));    % Function to fit
            fcn = @(b) sum((fit(b,X) - Y).^2);                              % Least-Squares cost function
            [s fval exitflag] = fminsearch(fcn, [yr/2;  offset_guess]);                    % Minimize Least-Squares
            [R P] = corrcoef(fit(s,X),Y);
            R2 = R.*R;
            
            % if x0(nn) > 500
            %     'hello'
            % end
            % 
            % if s(1) > A/100
                list = [list;[x0(nn),s(1),s(2),R2(2),(X(2)-X(1)).*length(X)/per]];
            % end
            offset_guess = s(2);
            xp = X;% linspace(min(X),max(X));
            figure(1)
            plot(X,Y,'bo',  xp,fit(s,xp), 'k--')
            drawnow
            % fo = fitoptions('Method','NonlinearLeastSquares',...
            %     'Lower',[0,-inf,omega_D*0.999,x0(nn)*0.999],...
            %     'Upper',[2*A,inf,omega_D*1.001,x0(nn)*1.001],...
            %     'StartPoint',[(max(x_temp(end-100:end))-x0(nn)) b_start omega_D x0(nn)]);
            % ft = fittype('a*sin(b-c*x)+d','options',fo);
            % 
            % if i0+4<length(x_temp)
            %     [curve2,gof2] = fit(tvec(i0:end)',x_temp(i0:end)',ft);
            %     if gof2.rsquare > 0.8 && curve2.a > A/100
            %         b_start = curve2.b;
            %         list = [list;[x0(nn),curve2.a,curve2.b]];
            %     end
            % end
        end
    end

end