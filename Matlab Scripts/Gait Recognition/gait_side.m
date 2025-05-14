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


% Impostazioni principali
utenti = {'antonio', 'vittoria', 'carolina', 'raffaele'}; % Nomi degli utenti
posizioni = {'side'}; % Posizioni del sensore
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

function segn_standardizzato = standardizza_segnale(segnale)
    segn_standardizzato = zeros(size(segnale)); % Prealloca matrice
    for col = 1:size(segnale, 2) % Itera sugli assi (colonne)
        media = mean(segnale(:, col)); % Media
        deviazione_std = std(segnale(:, col)); % Deviazione standard
        segn_standardizzato(:, col) = (segnale(:, col) - media) / deviazione_std; % Standardizzazione Z-Score
    end
end

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
        dati_filtrati = filtra_segnale(dati, fs); % Filtraggio passa-basso 3 Hz
        dati_normalizzati = standardizza_segnale(dati_filtrati); % Standardizzazione Z-Score
        % Numero di acquisizioni disponibili
        num_acquisizioni = 3;
        for k = 1:num_acquisizioni

            utente_capitalized = strcat(upper(utente(1)), lower(utente(2:end)));

            % Crea una nuova finestra grafica per ogni grafico
            figure;
            sgtitle(sprintf('Normalized Signal: %s - %s (Acquisition %d)', utente_capitalized, posizione, k));
           

            % Estrai i dati dell'asse Y per questa acquisizione
            y = dati_normalizzati(:, (k-1)*3 + 2);
            x = 1:length(y);
            
            % Identificazione dei picchi per il Gait Cycle
            [pks, locs] = findpeaks(y, 'MinPeakProminence', 0.5);
            [troughs, trough_locs] = findpeaks(-y, 'MinPeakProminence', 0.5);
            
            % Selezione delle valli con valore Y inferiore a -1.4
            valid_troughs_idx = find(-troughs < -1.4);
            selected_troughs = -troughs(valid_troughs_idx);
            selected_trough_locs = trough_locs(valid_troughs_idx);
            
            % Identificazione delle fasi Swing e Stance
            swing_phases = [];
            stance_phases = [];
            
            % Identificare correttamente le fasi di swing
            for idx = 1:length(selected_trough_locs)
                prev_peak_idx = find(locs < selected_trough_locs(idx), 1, 'last');
                next_peak_idx = find(locs > selected_trough_locs(idx), 1, 'first');
                if ~isempty(prev_peak_idx) && ~isempty(next_peak_idx)
                    swing_phases = [swing_phases; locs(prev_peak_idx), selected_trough_locs(idx), locs(next_peak_idx)];
                end
            end
            
            % Identificare le fasi di stance evitando sovrapposizioni con swing
            for idx = 1:length(locs)-1
                % Verifica se la coppia di picchi contiene una fase di swing
                is_part_of_swing = any(swing_phases(:,1) == locs(idx) | swing_phases(:,3) == locs(idx+1));
                if ~is_part_of_swing
                    stance_phases = [stance_phases; locs(idx), locs(idx+1)];
                end
            end

            y = -y;
            
            % Grafico con colorazione delle fasi
            hold on;
            colored_regions = false(size(y)); % Vettore che tiene traccia delle regioni colorate
            
            % Colora la fase di Swing
            swing_plot = plot(nan, nan, 'g', 'LineWidth', 2); % Placeholder per la legenda
            for s = 1:size(swing_phases, 1)
                idx_range = swing_phases(s, 1):swing_phases(s, 3);
                plot(x(idx_range), y(idx_range), 'g', 'LineWidth', 2);
                colored_regions(idx_range) = true; % Marca i segmenti come colorati
                % Aggiungi linee tratteggiate verticali all'inizio e alla fine della fase di swing
                xline(x(swing_phases(s, 1)), 'k--', 'LineWidth', 1);
                xline(x(swing_phases(s, 3)), 'k--', 'LineWidth', 1);
            end
            
            % Colora la fase di Stance
            stance_plot = plot(nan, nan, 'r', 'LineWidth', 2); % Placeholder per la legenda
            for s = 1:size(stance_phases, 1)
                idx_range = stance_phases(s, 1):stance_phases(s, 2);
                plot(x(idx_range), y(idx_range), 'r', 'LineWidth', 2);
                colored_regions(idx_range) = true; % Marca i segmenti come colorati
                % Aggiungi linee tratteggiate verticali all'inizio e alla fine della fase di stance
                xline(x(stance_phases(s, 1)), 'k--', 'LineWidth', 1);
                xline(x(stance_phases(s, 2)), 'k--', 'LineWidth', 1);
            end
            
            % Colora il segnale Y solo nei segmenti non colorati
            y_plot = plot(nan, nan, 'k', 'LineWidth', 1.5); % Placeholder per la legenda
            % Segnale originale in nero solo dove non appartiene a nessuna fase
            uncolored_segments = find(~colored_regions); % Trova i segmenti non colorati
            segment_start = uncolored_segments([true; diff(uncolored_segments) > 1]); % Inizio dei segmenti
            segment_end = uncolored_segments([diff(uncolored_segments) > 1; true]); % Fine dei segmenti
            for seg = 1:length(segment_start)
                plot(x(segment_start(seg):segment_end(seg)), y(segment_start(seg):segment_end(seg)), 'k', 'LineWidth', 1.5);
            end
            
            % Aggiungi la legenda
            legend([swing_plot, stance_plot, y_plot], ...
                {'Swing Phase', 'Stance Phase', 'Y-Signal'}, 'Location', 'best');
            
            hold off;
            xlabel('Samples');
            ylabel('Acceleration');
            grid on;



            % **Seleziona solo le colonne relative all'asse Y**
            y_data = dati_filtrati(:, [2, 5, 8]); % Estrai solo i dati dell'asse Y
            
            % **Calcolo Feature**  
            % Durata della fase di Stance e Swing
            stance_durations = (stance_phases(:,2) - stance_phases(:,1)) / fs; % Durata in secondi
            swing_durations = (swing_phases(:,3) - swing_phases(:,1)) / fs; % Durata in secondi
            
            % Cadence: numero di passi al minuto
            num_steps = length(selected_trough_locs);
            duration_seconds = num_campioni / fs;
            cadence = (num_steps / duration_seconds) * 60; % Passi al minuto
            
            % Inizializza array per memorizzare i campioni appartenenti alle fasi stance e swing
            valid_acc = [];
            
            % Estrai i campioni delle fasi di stance
            for s = 1:size(stance_phases, 1)
                valid_acc = [valid_acc; y(stance_phases(s, 1):stance_phases(s, 2))];
            end
            
            % Estrai i campioni delle fasi di swing
            for s = 1:size(swing_phases, 1)
                valid_acc = [valid_acc; y(swing_phases(s, 1):swing_phases(s, 3))];
            end
            
            % Calcola la media e la deviazione standard solo sui campioni selezionati
            mean_acc = mean(valid_acc);
            std_acc = std(valid_acc);

            
            % Rapporto tra durata Swing e Stance
            if ~isempty(stance_durations) && ~isempty(swing_durations)
                swing_stance_ratio = mean(swing_durations) / mean(stance_durations);
                swing_gait_ratio = mean(swing_durations) / (mean(swing_durations)+ mean(stance_durations));
            else
                swing_stance_ratio = NaN; % Evita divisioni per zero

            end


            
            % Struttura delle feature
            features = struct();
            features.mean_acc = mean_acc; % Media finale tra le acquisizioni
            features.std_acc = std_acc; % Media finale della deviazione standard (per tutte le colonne)
            features.stance_duration = mean(stance_durations); % Media durata stance
            features.swing_duration = mean(swing_durations); % Media durata swing
            features.cadence = cadence; % Passi al minuto
            features.swing_stance_ratio = swing_stance_ratio; % Rapporto tra durata Swing e Stance
            features.swing_gait_ratio = swing_gait_ratio;
            fprintf('\nRisultati per l''utente: %s all''acquisizione n. %u\n', utente, k);
            disp(features);


        end
    end
end