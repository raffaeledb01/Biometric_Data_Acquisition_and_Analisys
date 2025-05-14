clc;
clear all;
close all;

% Impostazioni principali
utenti = {'antonio', 'vittoria', 'carolina', 'raffaele'}; % Nomi degli utenti
posizioni = {'top'}; % Posizioni del sensore
fase_labels = {'Stance', 'Swing'};
num_campioni = 279; % Numero di campioni da prendere per colonna
fs = 27.9; % Frequenza di campionamento (279 campioni in 10 secondi)

function dati = carica_dati(nome_file, num_campioni)
    % Leggi il file come una tabella di stringhe
    dati_raw = readtable(nome_file, 'ReadVariableNames', false, 'TextType', 'string');
    
    % Numero di righe nel file
    num_righe = height(dati_raw);
    
    % Trova la prima riga che contiene dati validi
    first_data_row = find(contains(dati_raw{:, 1}, 'ACC(xyz):'), 1);
    
    % Se non ci sono dati validi, avvisa l'utente
    if isempty(first_data_row)
        error('Nessun dato valido trovato nel file.');
    end
    
    % Slicing della tabella per rimuovere le righe di intestazione
    dati_raw = dati_raw(first_data_row:end, :);
    
    % Verifica che il file contenga almeno num_campioni righe
    if height(dati_raw) < num_campioni
        warning('Il file contiene meno righe di quelle necessarie per caricare %d campioni. Vengono utilizzati i dati disponibili.', num_campioni);
        num_campioni = height(dati_raw);  % Adatta il numero di campioni da caricare
    end
    
    % Inizializza una matrice per i dati numerici (9 colonne: 3 per ogni acquisizione)
    dati = zeros(num_campioni, 9);  % Ogni riga contiene 9 valori: 3 per ciascuna delle 3 acquisizioni
    
    % Ciclo per estrarre i dati da ogni riga del file
    for i = 1:num_campioni
        % Estrai i dati della riga i
        riga = dati_raw{i, :};
        
        % Ciclo per ogni acquisizione (3 colonne per ogni riga)
        for col_idx = 1:3
            % Estrai i valori XYZ per la colonna corrispondente
            valori = str2double(regexp(riga{col_idx}, '-?\d+(\.\d+)?', 'match'));  % Estrai i numeri
            
            % Verifica che ci siano esattamente 3 valori (X, Y, Z)
            if length(valori) == 3
                % Assegna i valori nelle 3 colonne appropriate
                dati(i, (col_idx - 1) * 3 + 1) = valori(1);  % Asse X
                dati(i, (col_idx - 1) * 3 + 2) = valori(2);  % Asse Y
                dati(i, (col_idx - 1) * 3 + 3) = valori(3);  % Asse Z
            else
                warning('La riga %d, colonna %d non contiene 3 numeri validi per X, Y, Z.', i, col_idx);
            end
        end
    end
end


% Filtraggio del segnale
function segn_filtrato = filtra_segnale(segnale, fs)
    fc = 3; % Frequenza di taglio
    [b, a] = butter(4, fc / (fs / 2), 'low'); % Filtro passa-basso
    segn_filtrato = filtfilt(b, a, segnale); % Applica filtro
end

% Oppure usa la standardizzazione Z-Score
function segn_standardizzato = standardizza_segnale(segnale)
    segn_standardizzato = zeros(size(segnale)); % Prealloca matrice
    for col = 1:size(segnale, 2) % Itera sugli assi (colonne)
        media = mean(segnale(:, col)); % Media
        deviazione_std = std(segnale(:, col)); % Deviazione standard
        segn_standardizzato(:, col) = (segnale(:, col) - media) / deviazione_std; % Standardizzazione Z-Score
    end
end

% Funzione per trovare picchi e minimi per determinare gli intervalli di camminata (solo asse specifico)
function [swing_intervals, stance_intervals] = trova_intervalli_gait_cycle(dati_normalizzati, fs)
    % Inizializza le variabili per memorizzare gli intervalli
    swing_intervals = [];
    stance_intervals = [];
    
    % Trova i picchi nel segnale
    [picchi, pos_picchi] = findpeaks(dati_normalizzati, 'MinPeakDistance', 20, 'MinPeakHeight', 1.5);
    
    % Trova i minimi nel segnale
    [minimi, pos_minimi] = findpeaks(-dati_normalizzati);  % Minimi sono i picchi della versione invertita del segnale
    
    % Ciclo per ogni picco trovato
    for i = 1:length(picchi)
        picco_idx = pos_picchi(i);  % Indice del picco
        
        % Trova il primo minimo prima e dopo il picco
        % Primo minimo prima del picco
        min_prim_before = find(pos_minimi < picco_idx, 1, 'last');
        % Primo minimo dopo il picco
        min_prim_after = find(pos_minimi > picco_idx, 1, 'first');
        
        if ~isempty(min_prim_before) && ~isempty(min_prim_after)
            % Definisci l'intervallo di Swing
            swing_intervals = [swing_intervals; pos_minimi(min_prim_before), pos_minimi(min_prim_after)];
            
            % Trova il primo minimo dopo il picco i e il primo minimo prima del picco successivo
            if i + 1 <= length(picchi)
                % Primo minimo dopo il picco i
                min_after_i = find(pos_minimi > pos_picchi(i), 1, 'first');
                % Primo minimo prima del picco successivo
                min_before_next_peak = find(pos_minimi < pos_picchi(i+1), 1, 'last');
                
                if ~isempty(min_after_i) && ~isempty(min_before_next_peak)
                    % Definisci l'intervallo di Stance
                    stance_intervals = [stance_intervals; pos_minimi(min_after_i), pos_minimi(min_before_next_peak)];
                end
            end
        end
    end
end


function estrai_feature_swing_stance(swing_intervals, stance_intervals, dati_z, fs, utente, acquisizione)
    % Seleziona i campioni che appartengono agli intervalli di swing e stance
    swing_samples = [];
    stance_samples = [];
    
    % Aggiungi i campioni delle fasi di Swing
    for i = 1:size(swing_intervals, 1)
        swing_samples = [swing_samples; dati_z(swing_intervals(i, 1):swing_intervals(i, 2))];
    end
    
    % Aggiungi i campioni delle fasi di Stance
    for i = 1:size(stance_intervals, 1)
        stance_samples = [stance_samples; dati_z(stance_intervals(i, 1):stance_intervals(i, 2))];
    end
    
    % Unisci i campioni di Swing e Stance
    all_samples = [swing_samples; stance_samples];
    
    % Calcola la media dell'accelerazione solo per i campioni selezionati
    mean_acc = mean(all_samples) / 100;
    
    % Calcola la deviazione standard dell'accelerazione per i campioni selezionati
    std_acc = std(all_samples) / 100;
    
    % Durata della fase di Swing
    swing_durations = (swing_intervals(:,2) - swing_intervals(:,1)) / fs;
    mean_swing_duration = mean(swing_durations);
    
    % Durata della fase di Stance
    stance_durations = (stance_intervals(:,2) - stance_intervals(:,1)) / fs;
    mean_stance_duration = mean(stance_durations);
    
    % Calcolo della cadenza (passi al minuto)
    num_steps = length(swing_intervals); % Numero di passi è uguale agli intervalli di Swing
    total_time = length(dati_z) / fs;
    cadence = (num_steps / total_time) * 60;
    
    % Calcolo dei rapporti
    swing_stance_ratio = mean_swing_duration / mean_stance_duration;
    swing_gait_ratio = mean_swing_duration / (mean_swing_duration + mean_stance_duration);
    
    % Stampa delle feature
    fprintf('Utente: %s | Acquisizione: %d\n', utente, acquisizione);
    fprintf('Mean Acceleration: %.4f m/s^2\n', mean_acc);
    fprintf('Std Acceleration: %.4f m/s^2\n', std_acc);
    fprintf('Swing Duration: %.4f s\n', mean_swing_duration);
    fprintf('Stance Duration: %.4f s\n', mean_stance_duration);
    fprintf('Cadence: %.2f steps/min\n', cadence);
    fprintf('Swing/Stance Ratio: %.4f\n', swing_stance_ratio);
    fprintf('Swing/Gait Ratio: %.4f\n', swing_gait_ratio);
    fprintf('--------------------------------------\n');
end



% Modifica nel loop principale per aggiungere il calcolo degli intervalli di gait cycle (solo asse Z)
for i = 1:length(utenti)
    utente = utenti{i};
    for j = 1:length(posizioni)
        posizione = posizioni{j};
        % Nome del file
        nome_file = sprintf('gait_%s_%s.xlsx', utente, posizione);
        
        % Caricamento dati
        dati = carica_dati(nome_file, num_campioni);
        
        % Verifica dei dati
        if isempty(dati)
            warning('I dati per %s non sono stati caricati correttamente', nome_file);
            continue;
        end
        
        % Preprocessing
        dati_filtrati = filtra_segnale(dati, fs); % Filtraggio passa-basso
        dati_normalizzati = standardizza_segnale(dati_filtrati); % Standardizzazione Z-Score

        % Ciclo per elaborare ogni acquisizione (3 colonne per volta)
        for k = 1:3:9
            % Calcolo degli intervalli di Swing e Stance (solo asse Z della colonna corrente)
            [swing_intervals, stance_intervals] = trova_intervalli_gait_cycle(dati_normalizzati(:, k+2), fs);
            

            utente_capitalized = strcat(upper(utente(1)), lower(utente(2:end)));
         
            
            % Visualizzazione dei grafici (solo asse Z)
            figure;
            t = (0:size(dati_normalizzati, 1) - 1) / fs; % Asse temporale basato sulla frequenza di campionamento

            % Visualizza il segnale dell'asse Z per la colonna corrente
            plot(t, dati_normalizzati(:, k+2), 'k-', 'LineWidth', 1.5); % Segnale normalizzato (nero)
            hold on;
            % Colora il segnale Y solo nei segmenti non colorati
            z_plot = plot(nan, nan, 'k', 'LineWidth', 1.5); % Placeholder per la legenda

            % Colora la fase di Swing
            swing_plot = plot(nan, nan, 'g', 'LineWidth', 2); % Placeholder per la legenda
            % Colora i segmenti di Swing (in verde)
            for m = 1:size(swing_intervals, 1)
                % Estrai gli intervalli di tempo per il swing
                t_swing = t(swing_intervals(m, 1):swing_intervals(m, 2));
                segn_swing = dati_normalizzati(swing_intervals(m, 1):swing_intervals(m, 2), k+2);
                plot(t_swing, segn_swing, 'g', 'LineWidth', 2); % Colore verde per il swing
            end

            
            % Colora la fase di Stance
            stance_plot = plot(nan, nan, 'r', 'LineWidth', 2); % Placeholder per la legenda
            % Colora i segmenti di Stance (in rosso)
            for m = 1:size(stance_intervals, 1)
                % Estrai gli intervalli di tempo per il stance
                t_stance = t(stance_intervals(m, 1):stance_intervals(m, 2));
                segn_stance = dati_normalizzati(stance_intervals(m, 1):stance_intervals(m, 2), k+2);
                plot(t_stance, segn_stance, 'r', 'LineWidth', 2); % Colore rosso per il stance
            end

            % Aggiungi linee verticali nei punti di picco e minimo
            for m = 1:size(swing_intervals, 1)
                % Linea verticale per il primo intervallo di swing
                line([t(swing_intervals(m, 1)) t(swing_intervals(m, 1))], ylim, 'Color', 'k', 'LineStyle', '--', 'LineWidth', 1);
                % Linea verticale per il secondo intervallo di swing
                line([t(swing_intervals(m, 2)) t(swing_intervals(m, 2))], ylim, 'Color', 'k', 'LineStyle', '--', 'LineWidth', 1);
            end
            for m = 1:size(stance_intervals, 1)
                % Linea verticale per il primo intervallo di stance
                line([t(stance_intervals(m, 1)) t(stance_intervals(m, 1))], ylim, 'Color', 'k', 'LineStyle', '--', 'LineWidth', 1);
                % Linea verticale per il secondo intervallo di stance
                line([t(stance_intervals(m, 2)) t(stance_intervals(m, 2))], ylim, 'Color', 'k', 'LineStyle', '--', 'LineWidth', 1);
            end

            % Titolo e etichette
            xlabel('Time [s]');
            ylabel('Acceleration');
            % Aggiungi la legenda
            legend([swing_plot, stance_plot, z_plot], ...
                {'Swing Phase', 'Stance Phase', 'Z-Signal'}, 'Location', 'best');
            grid on;

            sgtitle(sprintf('Normalized Signal: %s - %s (Acquisition %d)', utente_capitalized, posizione, ceil(k/3))); % Titolo generale

        
            
            % Estrazione delle feature per ogni ciclo (solo asse Z)
            estrai_feature_swing_stance(swing_intervals, stance_intervals, dati_filtrati(:, k+2), fs, utente_capitalized, ceil(k/3));
        end
    end
end



