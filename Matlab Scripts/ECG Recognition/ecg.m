clc;
clear all;
close all;

% Imposta parametri di default per le figure
%set(0, 'DefaultFigureColor', 'w'); % Sfondo bianco
set(0, 'DefaultAxesFontSize', 14); % Dimensione carattere assi
%set(0, 'DefaultAxesFontWeight', 'Bold'); % Testo in grassetto
%set(0, 'DefaultLineLineWidth', 2); % Spessore linee
set(0, 'DefaultAxesLineWidth', 1); % Spessore assi
%set(0, 'DefaultAxesGridLineStyle', '--'); % Stile griglia tratteggiato
%set(0, 'DefaultAxesXGrid', 'on', 'DefaultAxesYGrid', 'on'); % Abilita la griglia
%set(0, 'DefaultFigurePosition', [200 200 800 600]); % Dimensione e posizione finestra
set(0, 'DefaultLegendFontSize', 14);

% Name of the CSV file
file_name = 'ecg_vittoria.CSV';

% Reading the data from the CSV file
raw_data = readmatrix(file_name, 'NumHeaderLines', 19); % Skip the first 19 header lines

fs = 1000; % Sampling frequency in Hz (1 kHz)

% Extracting the time and amplitude columns
time = raw_data(:, 4);          % Time column (seconds)
ecg_signal = raw_data(:, 5);    % Amplitude column (Volt)

% Apply attenuation factor if necessary (for signal adjustment)
probe_attenuation = 10; % Probe attenuation factor
% no - probe_attenuation; % Amplifying the ECG signal
ecg_signal = ecg_signal -1.55;

% Low-pass filtering to reduce noise
fc = 30; % Cutoff frequency (Hz)
[b, a] = butter(4, fc / (fs / 2), 'low'); % Design a low-pass Butterworth filter
filtered_ecg = filtfilt(b, a, ecg_signal); % Apply the filter to the ECG signal

% R-peak detection using the filtered ECG signal
[peaks_R, locs_R] = findpeaks(filtered_ecg, time, 'MinPeakHeight', 0.05, 'MinPeakDistance', 0.6);

% Initialize empty arrays for P, Q, S, and T peaks
locs_Q = []; locs_S = []; locs_P = []; locs_T = [];

% Loop through each detected R-peak to find the corresponding Q, S, P, and T peaks
for i = 1:length(locs_R)
    
    % Region around the R-peak to define the search window for Q, S, P, and T
    region_start = round((locs_R(i) - 0.3) * fs); % Start of the window (0.3 seconds before R-peak)
    region_end = round((locs_R(i) + 0.3) * fs);   % End of the window (0.3 seconds after R-peak)
    
    % Ensure that the indices are valid within the signal length
    region_start = max(1, region_start); % At least 1 (avoid negative indices)
    region_end = min(length(filtered_ecg), region_end); % Do not exceed the signal length
    
    % Index of the R-peak
    R_idx = round(locs_R(i) * fs);
    
    % Define the window for the Q-peak (e.g., 60 ms before the R-peak)
    region_start_Q = round((locs_R(i) - 0.06) * fs);  % 60 ms before the R-peak
    region_end_Q = round((locs_R(i) - 0.01) * fs);   % Up to the R-peak
    
    % Ensure that the indices are valid
    region_start_Q = max(1, region_start_Q);  % At least 1
    region_end_Q = min(length(filtered_ecg), region_end_Q);  % Do not exceed the signal length
    
    % Find the minimum value (Q) in the window
    [Q_val, Q_rel_idx] = min(filtered_ecg(region_start_Q:region_end_Q));

    % Convert the relative index within the window to a global index
    Q_global_idx = region_start_Q + Q_rel_idx - 1;
    
    % Calculate the time corresponding to the Q-peak
    locs_Q(i) = time(Q_global_idx);  % Time of the Q-peak

    % Define the window for the S-peak (e.g., 5 ms after R-peak to 30 ms after)
    region_start_S = round((locs_R(i) + 0.005) * fs);  % 5 ms after R-peak
    region_end_S = round((locs_R(i) + 0.03) * fs);    % Up to 30 ms after R-peak
    
    % Ensure that the indices are valid
    region_start_S = max(1, region_start_S);  % At least 1
    region_end_S = min(length(filtered_ecg), region_end_S);  % Do not exceed the signal length
    
    % Find the minimum value (S) in the window
    [S_val, S_rel_idx] = min(filtered_ecg(region_start_S:region_end_S));

    % Convert the relative index within the window to a global index
    S_global_idx = region_start_S + S_rel_idx - 1;
    
    % Calculate the time corresponding to the S-peak
    locs_S(i) = time(S_global_idx);  % Time of the S-peak
    
    % Define the window for the P-peak (e.g., 200 ms before R-peak)
    region_start_P = round((locs_R(i) - 0.2) * fs);  % 200 ms before R-peak
    region_end_P = round((locs_R(i) - 0.1) * fs);   % Up to 100 ms before R-peak
    
    % Ensure that the indices are valid
    region_start_P = max(1, region_start_P);  % At least 1
    region_end_P = min(length(filtered_ecg), region_end_P);  % Do not exceed the signal length
    
    % Find the maximum value (P) in the window
    [P_val, P_rel_idx] = max(filtered_ecg(region_start_P:region_end_P));

    % Convert the relative index within the window to a global index
    P_global_idx = region_start_P + P_rel_idx - 1;
    
    % Calculate the time corresponding to the P-peak
    locs_P(i) = time(P_global_idx);  % Time of the P-peak
    
    % Define the window for the T-peak (e.g., 100 ms after R-peak)
    region_start_T = round((locs_R(i) + 0.1) * fs);  % 100 ms after R-peak
    region_end_T = round((locs_R(i) + 0.3) * fs);   % Up to 300 ms after R-peak
    
    % Ensure that the indices are valid
    region_start_T = max(1, region_start_T);  % At least 1
    region_end_T = min(length(filtered_ecg), region_end_T);  % Do not exceed the signal length
    
    % Find the maximum value (T) in the window
    [T_val, T_rel_idx] = max(filtered_ecg(region_start_T:region_end_T));

    % Convert the relative index within the window to a global index
    T_global_idx = region_start_T + T_rel_idx - 1;
    
    % Calculate the time corresponding to the T-peak
    locs_T(i) = time(T_global_idx);  % Time of the T-peak

end

% Plot the ECG signal and the detected peaks
figure;
plot(time, filtered_ecg, 'k', 'DisplayName', 'ECG Signal', 'LineWidth', 1); % Plot the filtered ECG signal
hold on;
plot(locs_R, peaks_R, 'ro', 'DisplayName', 'R Peaks', 'LineWidth', 2, 'MarkerSize', 8);  % R Peaks con marker più grandi
plot(locs_P, interp1(time, filtered_ecg, locs_P), 'go', 'DisplayName', 'P Peaks', 'LineWidth', 2, 'MarkerSize', 8);  % P Peaks con marker più grandi
plot(locs_Q, interp1(time, filtered_ecg, locs_Q), 'bo', 'DisplayName', 'Q Peaks', 'LineWidth', 2, 'MarkerSize', 8);  % Q Peaks con marker più grandi
plot(locs_S, interp1(time, filtered_ecg, locs_S), 'o', 'DisplayName', 'S Peaks', 'LineWidth', 2, 'MarkerSize', 8,"MarkerEdgeColor","[0.9290 0.6940 0.1250]");  % S Peaks con marker più grandi
plot(locs_T, interp1(time, filtered_ecg, locs_T), 'mo', 'DisplayName', 'T Peaks', 'LineWidth', 2, 'MarkerSize', 8);  % T Peaks con marker più grandi


legend();  % Display the legend
xlabel('Time [s]');  % Label the x-axis
ylabel('Amplitude [mV]');  % Label the y-axis
title('ECG Signal with detected peaks');  % Title of the plot
grid on;  % Enable grid for better visualization



% Feature calculations
R_heights = max(peaks_R - interp1(time, filtered_ecg, locs_S));
S_heights = interp1(time, filtered_ecg, locs_S);

max_R = max(R_heights);
min_R = min(R_heights);
mean_R = mean(R_heights);
std_R = std(R_heights);


QRS_durations = locs_S - locs_Q;
mean_QRS_duration = mean(QRS_durations);


RR_intervals = diff(locs_R);
mean_RR = mean(RR_intervals);
heart_rate = 60 / mean_RR;

% Calcolo intervallo medio PQ
PQ_intervals = locs_P - locs_Q; % Differenza di tempo tra P e Q
mean_PQ_interval = mean(PQ_intervals);

% Calcolo intervallo medio ST
ST_intervals = locs_T - locs_S; % Differenza di tempo tra S e T
mean_ST_interval = mean(ST_intervals);

% Displaying results
fprintf('Max R: %f\n', max_R);
fprintf('Min R: %f\n', min_R);
fprintf('Mean R: %f\n', mean_R);
fprintf('Std R: %f\n', std_R);
fprintf('Mean QRS duration: %f s\n', mean_QRS_duration);
fprintf('Mean RR interval: %f s\n', mean_RR);
fprintf('Mean PQ interval: %f s\n', mean_PQ_interval);
fprintf('Mean ST interval: %f s\n', mean_ST_interval);
fprintf('Heart rate: %f bpm\n', heart_rate);


