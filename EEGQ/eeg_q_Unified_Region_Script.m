% Clear workspace, close all figures, and clear the command window
clear all;
close all;
clc;

% Define base directories (update with your own paths)
dataDir   = 'path/to/baseline/data/';      % Folder containing .set files
reportDir = 'path/to/baseline/report/';    % Folder for CSV output
mkdir(reportDir);

% Frequency markers and overall range (for plotting or analysis)
freqMap         = [3 11 22 34];
freqRange       = [2 40];
channelsToRemove = {'Cz','Status','trigger'};  % Channels to exclude from analysis

% Define EEG rhythms and their frequency bands
rhythms   = {'Delta','Theta','Alpha','Beta'};
freqStart = [0.5,   4,    8,    13];    % Lower bound of each band (Hz)
freqEnd   = [3.99, 7.99, 12.99, 30];    % Upper bound of each band (Hz)

% Specify epoch range for trimming
epochStart = 1;   % First epoch to keep
epochEnd   = 30;  % Last epoch to keep (-1 means keep all epochs)

%% Define brain regions and their corresponding electrodes
regions = {'Frontal','Central','TemporalRight','TemporalLeft','Parietal','Occipital'};
regionElectrodes = {
    {'FP2','AF4','F10','F8','F6','F4','FP1','AF3','F9','F7','F5','F3'},        % Frontal
    {'FC6','FC4','FC2','F2','C6','C4','C2','FC5','FC3','FC1','F1','C5','C3','C1'}, % Central
    {'TP8','FT8','T10','T8'},                                                  % TemporalRight
    {'TP7','FT7','T9','T7'},                                                   % TemporalLeft
    {'CP6','CP4','CP2','P10','P8','P6','P4','P2','CP5','CP3','CP1','P9','P7','P5','P3','P1'}, % Parietal
    {'PO4','O2','PO3','O1'}                                                    % Occipital
};

%% List all .set files
setFiles = dir(fullfile(dataDir, '*.set'));
nFiles   = numel(setFiles);

%% Load first file to capture channel labels
EEG = pop_loadset('filename', setFiles(1).name, 'filepath', dataDir);

% Standardize labels to uppercase
for i = 1:EEG.nbchan
    EEG.chanlocs(i).labels = upper(EEG.chanlocs(i).labels);
end

% Remove unwanted channels
EEG = pop_select(EEG, 'nochannel', upper(channelsToRemove));
nChannels = EEG.nbchan;

% Store remaining channel names
for i = 1:nChannels
    channelNames{i} = EEG.chanlocs(i).labels;
end
clear EEG;

%% Preallocate result storage
powerResults = cell(length(rhythms), nFiles, 3); % [rhythm, epochs, spectrum]
powerStd     = cell(length(rhythms), nFiles, 1); % standard deviations

%% Main processing loop
for fIdx = 1:nFiles
    fprintf('Processing %s...\n', setFiles(fIdx).name);
    
    % Load dataset
    EEG = pop_loadset('filename', setFiles(fIdx).name, 'filepath', dataDir);
    % Remove specified channels
    EEG = pop_select(EEG, 'nochannel', channelsToRemove);
    EEG = eeg_checkset(EEG);
    
    % Adjust epochEnd if using -1 to indicate “all epochs”
    if epochEnd == -1
        epochEnd = EEG.trials;
    end
    
    % Determine epochs to reject outside the [epochStart, epochEnd] range
    rejectEpochs = [];
    if epochStart > 1
        rejectEpochs = [1:(epochStart-1)];
    end
    if epochEnd < EEG.trials
        rejectEpochs = [rejectEpochs, (epochEnd+1):EEG.trials];
    end
    EEG = pop_rejepoch(EEG, rejectEpochs, 0);
    
    % Extract data parameters
    nPoints  = EEG.pnts;      % Number of data points per epoch
    nEpochs  = EEG.trials;    % Number of epochs
    sRate    = EEG.srate;     % Sampling rate
    data     = EEG.data;      % EEG data matrix
    chanIdx  = 1:EEG.nbchan;  % Channel indices
    
    % Compute mean spectral power for each rhythm
    for r = 1:length(rhythms)
        fprintf('  Calculating %s power...\n', rhythms{r});
        spec = meanfreq2(...
            freqStart(r), freqEnd(r), ...
            chanIdx, nPoints, nEpochs, sRate, data ...
        );
        powerResults{r, fIdx, 2} = nEpochs;  % Store number of epochs
        powerResults{r, fIdx, 3} = spec;     % Store spectral power
        powerStd{r, fIdx, 1}     = std(spec);% Store standard deviation
    end
end

%% Generate CSV reports per rhythm
for r = 1:length(rhythms)
    rhythmName = rhythms{r};
    
    % Individual-level report
    indFile = fullfile(reportDir, [rhythmName '_IND.csv']);
    fid = fopen(indFile, 'w');
    fprintf(fid, 'FreqRange[%g,%g]\n', freqStart(r), freqEnd(r));
    fprintf(fid, 'Name;NumEpochs;MeanPower\n');
    for fIdx = 1:nFiles
        meanPow = mean(powerResults{r, fIdx, 3});
        fprintf(fid, '%s;%d;%.6f\n', ...
            setFiles(fIdx).name, ...
            powerResults{r, fIdx, 2}, ...
            meanPow ...
        );
    end
    fclose(fid);
    
    % Electrode-level report
    eleFile = fullfile(reportDir, [rhythmName '_ELE.csv']);
    fid = fopen(eleFile, 'w');
    fprintf(fid, 'FreqRange[%g,%g]\n', freqStart(r), freqEnd(r));
    fprintf(fid, 'Name;NumEpochs');
    fprintf(fid, ';%s', channelNames{:});
    fprintf(fid, '\n');
    for fIdx = 1:nFiles
        fprintf(fid, '%s;%d', setFiles(fIdx).name, powerResults{r, fIdx, 2});
        fprintf(fid, ';%.6f', powerResults{r, fIdx, 3});
        fprintf(fid, '\n');
    end
    fclose(fid);
    
    % Region-level report
    regFile = fullfile(reportDir, [rhythmName '_REG.csv']);
    fid = fopen(regFile, 'w');
    fprintf(fid, 'FreqRange[%g,%g]\n', freqStart(r), freqEnd(r));
    fprintf(fid, 'Name;NumEpochs');
    fprintf(fid, ';%s', regions{:});
    fprintf(fid, '\n');
    for fIdx = 1:nFiles
        fprintf(fid, '%s;%d', setFiles(fIdx).name, powerResults{r, fIdx, 2});
        for regIdx = 1:length(regions)
            % Find electrodes for this region
            elecIDs = find(ismember(channelNames, regionElectrodes{regIdx}));
            avgPower = mean(powerResults{r, fIdx, 3}(elecIDs));
            fprintf(fid, ';%.6f', avgPower);
        end
        fprintf(fid, '\n');
    end
    fclose(fid);
end

disp('Processing complete.');
