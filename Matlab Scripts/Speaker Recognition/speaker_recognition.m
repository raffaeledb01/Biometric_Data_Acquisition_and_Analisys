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
set(0, 'DefaultLegendFontSize', 8);

rng(123);  % Fissa il seed per la randomizzazione

% Lista dei file Excel (per ogni utente e rumore)
files = {
    'utente_1_Di_Benedetto.xlsx',
    'utente_2_Di_Benedetto.xlsx',
    'utente_3_Di_Benedetto.xlsx',
    'rumore.xlsx'
};

% Parametri
fs = 4000; % Frequenza di campionamento (Hz)
dt = 1 / fs; % Intervallo di campionamento (s)

% Pre-allocazione per i dati
segnali = {};
rumore = [];

% Lettura dei dati da ciascun file
for i = 1:length(files)
    % Leggi il file Excel
    data = readmatrix(files{i});
    
    % Salva i dati in una cella (segnali degli utenti)
    if i < 4
        segnali{i} = data;
    else
        rumore_graph = data;
        rumore = mean(data, 2);  % Calcola il rumore medio (media delle colonne)
    end
end

% Numero di acquisizioni per ogni file (9 per utente, 3 per rumore)
num_acquisizioni = size(segnali{1}, 2);

% Parametri di soglia e elaborazione
soglia_relativa = 0.03;
gamma = double(intmax('int16'));
soglia = soglia_relativa * gamma;
soglia_relativa2 = 0.71;

% Pre-allocazione per i segnali finali
segnali_finali = cell(1, 9);
indice_salvataggio = 1;

% Elaborazione dei segnali
segnali_senza_rumore = cell(length(segnali)-1, num_acquisizioni);
segnali_prima_soglia = cell(length(segnali)-1, num_acquisizioni);
t_utile_graph = cell(length(segnali)-1, num_acquisizioni);

% Elaborazione dei segnali
for i = 1:length(segnali)
    % Crea una nuova figura per ogni file
    figure('Name', ['Segnali - ' files{i}(1:end-5)], 'NumberTitle', 'off');
    
    % Asse temporale
    N = size(segnali{i}, 1);
    t = (0:N-1) * dt;
    
    % Elaborazione segnali
    for j = 1:num_acquisizioni
        subplot(num_acquisizioni, 1, j);  % Subplot per ogni acquisizione
        
        % Calcola il segnale pulito
        segnale_pulito = segnali{i}(:, j) - rumore;
        segnali_senza_rumore{i, j} = segnale_pulito; % Salva il segnale senza rumore
        non_silenzio = abs(segnale_pulito) > soglia;
        inizio = find(non_silenzio, 1, 'first');
        fine = find(non_silenzio, 1, 'last');
        
        if ~isempty(inizio) && ~isempty(fine)
            % Segnale utile
            segnale_utile = segnale_pulito(inizio:fine);
            segnali_prima_soglia{i, j} = segnale_utile;
            t_utile = t(inizio:fine);
            t_utile_graph{i, j} = t_utile;
            gamma2 = max(abs(segnale_utile));
            soglia2 = soglia_relativa2 * gamma2;
            
            % Plot del segnale originale e utile
            plot(t, segnale_pulito, 'b', 'DisplayName', 'Segnale originale');
            hold on;
            plot(t_utile, segnale_utile, 'r', 'DisplayName', 'Segnale utile');
            
            % Seconda soglia
            non_silenzio2 = abs(segnale_utile) > soglia2;
            inizio2 = find(non_silenzio2, 1, 'first');
            fine2 = find(non_silenzio2, 1, 'last');
            
            if ~isempty(inizio2) && ~isempty(fine2)
                segnale_finale = segnale_utile(inizio2:fine2);
                t_utile2 = t_utile(inizio2:fine2);
                
                plot(t_utile2, segnale_finale, 'g', 'DisplayName', 'Segnale utile (seconda soglia)');
                
                % Salva il segnale finale
                if indice_salvataggio <= 9
                    segnali_finali{indice_salvataggio} = segnale_finale;
                    indice_salvataggio = indice_salvataggio + 1;
                end
            end
        else
            % Segnale non utile: disegna un grafico vuoto
            plot(t, zeros(size(t)), 'b');  % Linea vuota
            title(['Nessun segnale utile per acquisizione ' num2str(j) ' - ' files{i}(1:end-5)]);
        end
        
        % Personalizza il grafico
        grid on;
        title(['Signal - Acquisition ' num2str(j) ' - ' files{i}(1:end-5)]);
        xlabel('Time [s]');
        ylabel('Amplitude [mV]');

        % Aggiungi gli oggetti per la legenda separati per ciascun utente
        s1 = plot(NaN, NaN, '-b', 'LineWidth', 2); 
        s2 = plot(NaN, NaN, '-r', 'LineWidth', 2); 
        s3 = plot(NaN, NaN, '-g', 'LineWidth', 2); 
        legend([s1, s2, s3], 'Denoised Signal', 'Speech Segment (1° Threshold)', 'Speech Segment (2° Threshold)');
        hold off;

    end
end

%%
%%{
% Generazione di una figura per ogni utente contenente tre grafici distinti

figure('Name', 'Saturazione', 'NumberTitle','off');
plot(t, segnali{1}(:, 1));
title('Acquisition 1 - Antonio - Di Benedetto');
xlabel('Time [s]');
ylabel('Amplitude [mV]');
grid on; 

for i = 1:3
    figure('Name', ['Signal User ' num2str(i)], 'NumberTitle', 'off');
    for j = 1:3
        subplot(3,1,j);
        plot(t, segnali{i}(:, j), 'DisplayName', ['Acquisition ' num2str(j)]);
        title(['Acquisition ' num2str(j) ' - User ' num2str(i)]);
        xlabel('Time [s]');
        ylabel('Amplitude [mV]');
        grid on;
    end
end

% Generazione di una figura con tre grafici per le acquisizioni del rumore
figure('Name', 'Noise Acquisition', 'NumberTitle', 'off');
for j = 1:3
    subplot(3,1,j);
    plot(t, rumore_graph(:, j), 'DisplayName', ['Noise Acquisition ' num2str(j)]);
    title(['Noise Acquisition ' num2str(j)]);
    xlabel('Time [s]');
    ylabel('Amplitude [mV]');
    grid on;
end

% Generazione di una figura con tre grafici per le acquisizioni del rumore
figure('Name', 'Average Noise', 'NumberTitle', 'off');
plot(t, rumore(:, 1));
title('Average Noise');
xlabel('Time [s]');
ylabel('Amplitude [mV]');
grid on;
%}

%{
% Generazione di una figura per ogni utente con le tre acquisizioni senza rumore
for i = 1:length(segnali)
    figure('Name', ['Segnali senza Rumore - Utente ' num2str(i)], 'NumberTitle', 'off');
    for j = 1:3
        subplot(3,1,j);
        plot(t, segnali_senza_rumore{i, j}, 'b', 'DisplayName', ['Acquisizione ' num2str(j)]);
        title(['Acquisizione ' num2str(j) ' - Utente ' num2str(i)]);
        xlabel('Tempo (s)');
        ylabel('Ampiezza');
        legend;
        grid on;
    end
end

% Generazione di una figura per ogni utente con le tre acquisizioni senza rumore
for i = 1:length(segnali)
    figure('Name', ['Segnali senza Rumore - Utente ' num2str(i)], 'NumberTitle', 'off');
    for j = 1:3
        subplot(3,1,j);
        plot(t, segnali_senza_rumore{i, j}, 'b', 'DisplayName', 'Segnale originale');
        hold on;
        plot(t_utile_graph{i, j}, segnali_prima_soglia{i, j}, 'r', 'DisplayName', 'Segnale utile');
        title(['Acquisizione ' num2str(j) ' - Utente ' num2str(i)]);
        xlabel('Tempo (s)');
        ylabel('Ampiezza');
        legend;
        grid on;
    end
end


%%
for i = 1:9

    [pxx, f] = pyulear(segnali_finali{i}, 12, 1024, fs);

    figure;
    plot(f, 10*log10(pxx), 'LineWidth', 1.5);
    xlabel('Frequenza (Hz)');
    ylabel('Densità spettrale di potenza (dB/Hz)');
    title('Stima della densità spettrale di potenza con metodo di Yule-Walker');
    grid on;

end
%}


%%

% Z-Score normalization for all signals
num_segnali = length(segnali_finali);
for i = 1:num_segnali
    segnali_finali{i} = (segnali_finali{i} - mean(segnali_finali{i})) / std(segnali_finali{i});
end

% Seleziona i segnali da aggiungere ai due nuovi vettori
segnali_finali_train = {segnali_finali{1}, segnali_finali{2}, segnali_finali{4}, segnali_finali{5}, segnali_finali{7}, segnali_finali{8}};
segnali_finali_test = {segnali_finali{3}, segnali_finali{6}, segnali_finali{9}};

% Mostra la lunghezza di entrambi i gruppi
disp('Primo gruppo (segnali_finali{1}, segnali_finali{2}, segnali_finali{4}, segnali_finali{5}, segnali_finali{7}, segnali_finali{8}):');
disp(length(segnali_finali_train));

disp('Secondo gruppo (segnali_finali{3}, segnali_finali{6}, segnali_finali{9}):');
disp(length(segnali_finali_test));

% Supponiamo che i segnali siano memorizzati nel vettore segnali_finali{1} ... segnali_finali{9}
% Ogni cella contiene un segnale diverso di lunghezza variabile

% Parametri di pre-elaborazione
frame_length = 256;   % Lunghezza del frame (numero di campioni)
frame_overlap = 128;  % Sovrapposizione tra i frame
fs = 4000;            % Frequenza di campionamento

% Inizializzazione del vettore per memorizzare gli MFCC
mfcc_all_users = cell(1, 6);

for i = 1:6
    % Carica il segnale
    signal = segnali_finali_train{i};
    
    % Calcolare gli MFCC per ciascun segnale
    % Utilizza la funzione mfcc di MATLAB per calcolare gli MFCC
    mfcc_all_users{i} = mfcc(signal, fs, 'Window', hamming(frame_length), 'OverlapLength', frame_overlap, 'NumCoeffs', 13);
end

for i = 1:6
    % Prendi la matrice degli MFCC per ciascun segnale
    mfcc_matrix = mfcc_all_users{i};
    
    % Memorizza le dimensioni (numero di frame e numero di coefficienti)
    dimensions(i, :) = size(mfcc_matrix);
end

% Stampa le dimensioni
disp(dimensions);

% Inizializzazione di un vettore per memorizzare i centroidi
centroidi = zeros(6, 14);  % 6 segnali, 14 coefficienti MFCC per centroide

for i = 1:6
    % Ottieni gli MFCC per il segnale i
    mfcc_signal = mfcc_all_users{i};
    
    % Calcola il centroide come la media per ciascun coefficiente MFCC
    centroide_signal = mean(mfcc_signal, 1);  % media lungo le righe (frame)
    
    % Memorizza il centroide
    centroidi(i, :) = centroide_signal;
end

% Definisci i colori per ogni utente come celle di stringhe
colori = {'r', 'g', 'b', 'w'}; % 'r' per Antonio, 'g' per Vittoria, 'b' per Raffaele

% Esegui la PCA per ridurre la dimensione da 14 a 2
[coeff, score, ~] = pca(centroidi);

% Crea un array di colori per ciascun centroide in base all'utente
utenti_colori = [repmat(colori{1}, 2, 1);  % 2 segnali per Antonio
                 repmat(colori{2}, 2, 1);  % 2 segnali per Vittoria
                 repmat(colori{3}, 2, 1)]; % 2 segnali per Raffaele

% Visualizza i centroidi nel nuovo spazio a 2 dimensioni
figure;
hold on;

% Plotta ogni centroide con il colore dell'utente corrispondente
for i = 1:6
    scatter(score(i, 1), score(i, 2), 100, 'MarkerFaceColor', utenti_colori(i,:), 'MarkerEdgeColor', 'k', 'LineWidth', 1.5);
end

% Aggiungi gli oggetti per la legenda separati per ciascun utente
h1 = scatter(NaN, NaN, 100, 'MarkerFaceColor', colori{1}, 'MarkerEdgeColor', 'k'); % Antonio
h2 = scatter(NaN, NaN, 100, 'MarkerFaceColor', colori{2}, 'MarkerEdgeColor', 'k'); % Vittoria
h3 = scatter(NaN, NaN, 100, 'MarkerFaceColor', colori{3}, 'MarkerEdgeColor', 'k'); % Raffaele

% Aggiungi legenda e dettagli
title('Speaker Codebook with Centroids for each User (Enrollment)');
xlabel('Principal Components 1');
ylabel('Principal Components 2');
grid on;
legend([h1, h2, h3], 'Antonio', 'Vittoria', 'Raffaele');
hold off;

%%


% Soglia per decidere l'appartenenza (definiscila in base ai tuoi dati)
soglia = 0.7; % Cambia questo valore a seconda della scala delle distanze

% Prealloca una cella per memorizzare i centroidi dei nuovi segnali
centroidi_nuovi_segnali = zeros(3, 14); % 3 nuovi segnali, 14 coefficienti MFCC

% Calcola i centroidi per ciascun nuovo segnale
for j = 1:3
    % Calcola i MFCC del nuovo segnale
    mfcc_nuovo_segnale = mfcc(segnali_finali_test{j}, fs, 'Window', hamming(frame_length), 'OverlapLength', frame_overlap, 'NumCoeffs', 13);
    % Calcola il centroide del nuovo segnale
    centroidi_nuovi_segnali(j, :) = mean(mfcc_nuovo_segnale, 1);
end

% Calcola la distanza tra i centroidi dei nuovi segnali e i centroidi esistenti
distanze = zeros(3, 6); % 3 nuovi segnali e 6 centroidi (3 per ciascun utente)

% Calcola le distanze Euclidee per ciascun nuovo segnale
for j = 1:3
    for i = 1:6
        distanze(j, i) = norm(centroidi_nuovi_segnali(j, :) - centroidi(i, :));
    end
end

% Matrice per memorizzare le medie delle distanze per ogni utente
medie_distanze = zeros(3, 3); % 3 nuovi segnali, 3 utenti

% Calcola la media delle distanze per ciascun utente
for j = 1:3
    % Distanza dai centroidi di 'Antonio' (1 e 2)
    medie_distanze(j, 1) = mean(distanze(j, 1:2));
    % Distanza dai centroidi di 'Vittoria' (3 e 4)
    medie_distanze(j, 2) = mean(distanze(j, 3:4));
    % Distanza dai centroidi di 'Raffaele' (5 e 6)
    medie_distanze(j, 3) = mean(distanze(j, 5:6));
end

% Stampa le medie delle distanze
disp('Medie delle distanze per ciascun utente:');
disp(medie_distanze);

% Classifica i nuovi segnali in base alla distanza minima sulle medie
utenti_classificati = cell(1, 3); % Memorizza il nome dell'utente o "No Match" per ogni nuovo segnale
utenti_reali = {'Antonio', 'Vittoria', 'Raffaele'}; % Utenti reali dei nuovi segnali
segnali_correttamente_classificati = 0; % Contatore per i segnali classificati correttamente
segnali_classificati = 0; % Contatore dei segnali assegnati a un utente

for j = 1:3
    % Trova la distanza minima e l'indice dell'utente candidato
    [distanza_minima, indice_utente] = min(medie_distanze(j, :));
    

    disp(distanza_minima)

    % Verifica se la distanza minima è sotto la soglia
    if distanza_minima < soglia
        % Associa il nuovo segnale all'utente corrispondente
        if indice_utente == 1
            utenti_classificati{j} = 'Antonio';
        elseif indice_utente == 2
            utenti_classificati{j} = 'Vittoria';
        else
            utenti_classificati{j} = 'Raffaele';
        end
        
        % Verifica se la classificazione è corretta
        if strcmp(utenti_classificati{j}, utenti_reali{j})
            segnali_correttamente_classificati = segnali_correttamente_classificati + 1;
        end
    else
        % Classifica il nuovo segnale come "No Match"
        utenti_classificati{j} = 'No Match';
    end
end

% Calcola l'accuracy solo per i segnali effettivamente classificati

accuracy = segnali_correttamente_classificati / length(segnali_finali_test);


% Visualizza l'accuracy
disp(['L''accuracy del sistema di classificazione è: ', num2str(accuracy * 100), '%']);

% Visualizza il risultato della classificazione
for j = 1:3
    disp(['Il nuovo segnale ', num2str(j), ' è stato classificato come appartenente a: ', utenti_classificati{j}]);
end




%%
% Unisce tutti i centroidi (iniziali e nuovi) in un'unica matrice
tutti_centroidi = [centroidi; centroidi_nuovi_segnali];

% Esegue la PCA per ridurre la dimensionalità a 2D
[coeff, score, ~] = pca(tutti_centroidi);

% Proietta i centroidi nello spazio bidimensionale
proiezioni_centroidi_iniziali = score(1:6, :); % I primi 6 centroidi iniziali
proiezioni_centroidi_nuovi = score(7:end, :);  % Gli ultimi 3 centroidi nuovi

% Colori per i centroidi nuovi in base agli utenti identificati
colori_nuovi = cell(1, 3); % Prealloca i colori per i nuovi centroidi

for j = 1:3
    if strcmp(utenti_classificati{j}, 'Antonio')
        colori_nuovi{j} = 'r'; % Rosso
    elseif strcmp(utenti_classificati{j}, 'Vittoria')
        colori_nuovi{j} = 'g'; % Verde
    elseif strcmp(utenti_classificati{j}, 'Raffaele')
        colori_nuovi{j} = 'b'; % Blu
    elseif strcmp(utenti_classificati{j}, 'No Match')
        colori_nuovi{j} = 'w'; % Bianco
    end
end

% Crea il grafico
figure;
hold on;

% Plot dei centroidi iniziali con contorno nero
for i = 1:3
    % Indici dei centroidi dell'utente i
    indici_iniziali = (2 * i - 1):(2 * i);
    scatter(proiezioni_centroidi_iniziali(indici_iniziali, 1), ...
            proiezioni_centroidi_iniziali(indici_iniziali, 2), ...
            100, colori{i}, 'o', 'filled', ...
            'MarkerEdgeColor', 'k', 'LineWidth', 1.5);
end

% Plot dei centroidi nuovi con contorno nero
for j = 1:3
    scatter(proiezioni_centroidi_nuovi(j, 1), ...
            proiezioni_centroidi_nuovi(j, 2), ...
            150, colori_nuovi{j}, '^', 'filled', ...
            'MarkerEdgeColor', 'k', 'LineWidth', 1.5);
end


% Aggiungi gli oggetti per la legenda separati per ciascun utente
p1 = scatter(NaN, NaN, 100, 'MarkerFaceColor', colori{1}, 'MarkerEdgeColor', 'k'); % Antonio
p2 = scatter(NaN, NaN, 100, 'MarkerFaceColor', colori{2}, 'MarkerEdgeColor', 'k'); % Vittoria
p3 = scatter(NaN, NaN, 100, 'MarkerFaceColor', colori{3}, 'MarkerEdgeColor', 'k'); % Raffaele
p4 = scatter(NaN, NaN, 100, 'MarkerFaceColor', colori{4}, 'MarkerEdgeColor', 'k'); % Raffaele

% Aggiunge punti di esempio per la forma con contorno nero
p5 = scatter(NaN, NaN, 100, 'o', 'MarkerEdgeColor', 'k', 'LineWidth', 1.5); % Cerchio vuoto con contorno nero
p6 = scatter(NaN, NaN, 100, '^', 'MarkerEdgeColor', 'k', 'LineWidth', 1.5); % Triangolo vuoto con contorno nero

% Aggiunge la legenda con le specifiche richieste

legend([p1, p2, p3, p4, p5, p6], 'Antonio', 'Vittoria', 'Raffaele', 'No Match', 'Centroids in DB', 'New Centroids');

% Configura il grafico
xlabel('Principal Components 1');
ylabel('Principal Components 2');
title('Speaker Codebook with Centroids for each User (Identification)');
grid on;
hold off;

