% =========================================================================
% MATLAB SCRIPT: Final Commercial Data Acquisition and Visualization
% TARGET ENVIRONMENT: MATLAB 2015 (FINAL SYNTAX VERIFIED)
% =========================================================================

% --- 1. SETUP AND CONNECTION ---
serial_port = 'COM4'; % CRITICAL: MATLAB listens on the paired port (COM4).
baud_rate = 9600;

% Clean up previous sessions
delete(instrfindall);

try
    % Initialize the serial object (Compatible for MATLAB 2015)
    s = serial(serial_port, 'BaudRate', baud_rate);

    set(s, 'Terminator', 'LF'); % Line Feed termination
    set(s, 'InputBufferSize', 4096);

    % Open the serial connection
    fopen(s);

    pause(0.5);

    disp('Serial connection opened successfully on COM4.');
    disp('*** ADJUST POTENTIOMETER IN PROTEUS (COM3) TO SEE DATA ***');

    % --- 2. INITIALIZATION ---
    % Initialize arrays
    Time_s = [];
    Temperature_C = [];

    data_points = 0;
    max_points = 60; % Show the last 60 seconds of data in the plot

    % Set up the live plot figure
    figure(1);
    h = plot(NaN, NaN, 'b-', 'LineWidth', 2);
    grid on;
    title('Real-Time Calibrated Temperature Monitoring (LM35)');
    xlabel('Elapsed Time (seconds)');
    ylabel('Temperature (°C)');

    % --- 3. MAIN DATA ACQUISITION LOOP ---
    while ishandle(h) % Loop continues as long as the plot window is open

        if s.BytesAvailable > 0
            % Read one line of text from the serial buffer
            data_string = fgetl(s);

            % Skip the initial header line ("TIME_MS,TEMPERATURE_C")
            if ~isempty(strfind(data_string, 'TIME_MS'))
                continue;
            end

            % Split the CSV string (e.g., "1000,25.50")
            data_values = sscanf(data_string, '%f,%f');

            if length(data_values) == 2

                data_points = data_points + 1;

                % Extract Time (convert ms to seconds) and Temperature
                current_time = data_values(1) / 1000;
                current_temp = data_values(2);

                % Store values
                Time_s(data_points) = current_time;
                Temperature_C(data_points) = current_temp;

                % --- PLOTTING LOGIC (Sliding Window) ---
                num_rows = length(Time_s);
                start_index = max(1, num_rows - max_points + 1);

                plot_time = Time_s(start_index:end);
                plot_temp = Temperature_C(start_index:end);

                % Update the plot in real-time
                set(h, 'XData', plot_time, 'YData', plot_temp);

                % Adjust plot limits dynamically
                if num_rows > 1
                    xlim([plot_time(1), plot_time(end) + 1]);
                    ylim([min(plot_temp) - 1, max(plot_temp) + 1]);
                end

                drawnow; % R2015a does NOT support drawnow limitrate
            end
        end
        pause(0.01);
    end

catch ME
    disp(['An error occurred during acquisition: ', ME.message]);
end

% === 4. CLEANUP AND FINAL DELIVERABLE (Data Logging) ===

% Ensure the serial connection is closed properly
if exist('s', 'var') && strcmp(s.Status, 'open')
    fclose(s);
    delete(s);
    clear s;
    disp('Serial connection closed.');
end

disp('Data acquisition finished. Starting data logging...');

% --- HIGH-VALUE DELIVERABLE: LOGGING TO EXCEL ---
if ~isempty(Time_s)
    
    % Create final matrix (column format)
    final_data_matrix = [Time_s(:), Temperature_C(:)];

    % Header for Excel
    header = {'Time_s', 'Temperature_C'};

    excel_filename = 'LM35_Temperature_Log.xlsx';

    % Write header and data
    xlswrite(excel_filename, header, 1, 'A1');
    xlswrite(excel_filename, final_data_matrix, 1, 'A2');

    disp(['Final data successfully logged to: ', excel_filename]);
else
    disp('No data collected or plot window closed immediately.');
end
