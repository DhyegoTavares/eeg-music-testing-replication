clear all;

% Subject name (can be left empty for batch processing)
subjectName = '';

% Define input and output folders
dataFolder   = 'path\to\your\set_files\';  % Update to your folder
reportFolder = 'path\to\your\report\';    % Update to your folder
mkdir(reportFolder);  % Create report folder if it does not exist

% Frequency markers and overall range
freqMarkers = [3 11 22 34];
freqRange   = [2 40];

% Channels to remove from analysis
channelsToRemove = {'Cz','Status','trigger'};

% Define EEG rhythms and their frequency bands
rhythms    = {'Delta', 'Theta', 'Alpha','Beta'};
freqStart  = [0.5, 4, 8, 13];      % Lower frequency of each rhythm (Hz)
freqEnd    = [3.99, 7.99, 12.99, 30]; % Upper frequency of each rhythm (Hz)

% Epoch range for trimming
epochStart = 1;   % First epoch to keep (1 = from the beginning)
epochEnd   = 30;  % Last epoch to keep (-1 = keep all epochs)

%% Define brain regions and corresponding electrodes
regions = {'FrontalRight','FrontalLeft','CentralRight','CentralLeft','TemporalRight','TemporalLeft','ParietalRight','ParietalLeft','OccipitalRight','OccipitalLeft'};

regionElectrodes = {  
    {'FP2','AF4','F10','F8','F6','F4'},       % Frontal right
    {'FP1','AF3','F9','F7','F5','F3'},       % Frontal left
    {'FC6','FC4','FC2','F2','C6','C4','C2'}, % Central right
    {'FC5','FC3','FC1','F1','C5','C3','C1'}, % Central left
    {'TP8','FT8','T10','T8'},                 % Temporal right
    {'TP7','FT7','T9','T7'},                  % Temporal left
    {'CP6','CP4','CP2','P10','P8','P6','P4','P2'}, % Parietal right
    {'CP5','CP3','CP1','P9','P7','P5','P3','P1'},  % Parietal left
    {'PO4','O2'},                             % Occipital right
    {'PO3','O1'}                              % Occipital left
};

%% Read .set files from folder
setFiles = dir([dataFolder, subjectName, '*.set']); % List all .set files
numFiles = length(setFiles);                        % Number of files

%% Load first file to get channel names
EEG = pop_loadset([dataFolder setFiles(1).name]);
numChannels = EEG.nbchan;

% Standardize channel labels to uppercase
for i = 1:numChannels
    EEG.chanlocs(i).labels = upper(EEG.chanlocs(i).labels);
end

% Remove unwanted channels
EEG = pop_select(EEG,'nochannel',upper(channelsToRemove));
numChannels = EEG.nbchan;

% Store remaining channel names
for i = 1:numChannels
    channelNames{i} = EEG.chanlocs(i).labels; 
end
clear EEG

%% Preallocate result storage
powerResults = cell(length(rhythms), numFiles, 3); % Spectral power per channel
powerStd     = cell(length(rhythms), numFiles, 1); % Standard deviation

%% MAIN LOOP: Process each file
for fIdx = 1:numFiles
    disp(['PROCESSING FILE -------------------- ' setFiles(fIdx).name]);
    
    % Load dataset
    EEG = pop_loadset([dataFolder setFiles(fIdx).name]);
    
    % Remove unwanted channels
    EEG = pop_select(EEG,'nochannel',channelsToRemove);
    EEG = eeg_checkset(EEG);
    
    % Adjust epoch end if epochEnd == -1 (all epochs)
    if epochEnd == -1
        epochEnd = EEG.trials;
    end
    
    % Define epochs to reject outside desired range
    rejectEpochs = [];
    if epochStart > 1
        rejectEpochs = [1:epochStart-1];
    end
    if epochEnd < EEG.trials
        rejectEpochs = [rejectEpochs epochEnd+1:EEG.trials];
    end
    EEG = pop_rejepoch(EEG, rejectEpochs, 0);
    
    %% Compute mean spectral power for each rhythm
    numPoints = EEG.pnts;      % Number of points per epoch
    numEpochs = EEG.trials;    % Number of epochs
    sRate     = EEG.srate;     % Sampling rate
    eegData   = EEG.data;      % EEG data matrix
    channelIdx = 1:EEG.nbchan; % Channel indices
    
    for r = 1:length(rhythms)
        disp(['Calculating power for ' rhythms{r}]);
        spec = meanfreq2(freqStart(r), freqEnd(r), channelIdx, numPoints, numEpochs, sRate, eegData);
        powerResults{r,fIdx,2} = numEpochs;  % Store number of epochs
        powerResults{r,fIdx,3} = spec;       % Store spectral power
        powerStd{r,fIdx,1}     = std(spec);  % Store standard deviation
    end
end

%% Generate individual-level CSV
for rIdx = 1:length(rhythms)
    fp = fopen([reportFolder rhythms{rIdx} '_IND.csv'], 'wt');
    fprintf(fp, 'Freq. Range[%g,%g]\n', freqStart(rIdx), freqEnd(rIdx));
    fprintf(fp,'Name;#Epochs;Power\n');
    
    for fIdx = 1:numFiles
        fprintf(fp,'%s;%d', setFiles(fIdx).name, powerResults{rIdx,fIdx,2});
        meanPower = mean(powerResults{rIdx,fIdx,3}); % Mean across channels
        fprintf(fp, ';%f\n', meanPower);
    end
    fclose(fp);

    %% Electrode-level CSV
    fp = fopen([reportFolder rhythms{rIdx} '_ELE.csv'], 'wt');
    fprintf(fp, 'Freq. Range[%g,%g]\n', freqStart(rIdx), freqEnd(rIdx));
    fprintf(fp,'Name;#Epochs');
    for c = 1:numChannels
        fprintf(fp, ';%s', channelNames{c});
    end
    fprintf(fp,'\n');
    
    for fIdx = 1:numFiles
        fprintf(fp,'%s;%d', setFiles(fIdx).name, powerResults{rIdx,fIdx,2});
        for c = 1:numChannels
            fprintf(fp, ';%f', powerResults{rIdx,fIdx,3}(c));
        end
        fprintf(fp,'\n');
    end
    fclose(fp);
    
    %% Region-level CSV
    fp = fopen([reportFolder rhythms{rIdx} '_REG.csv'], 'wt');
    fprintf(fp, 'Freq. Range[%g,%g]\n', freqStart(rIdx), freqEnd(rIdx));
    fprintf(fp,'Name;#Epochs');
    for regIdx = 1:length(regions)
        fprintf(fp, ';%s', regions{regIdx});
    end
    fprintf(fp,'\n');
    
    for fIdx = 1:numFiles
        fprintf(fp,'%s;%d', setFiles(fIdx).name, powerResults{rIdx,fIdx,2});
        for regIdx = 1:length(regions)
            sumPower = 0;
            count    = 0;
            for c = 1:numChannels
                idx = find(strcmpi(regionElectrodes{regIdx}, channelNames{c}));
                if ~isempty(idx)
                    sumPower = sumPower + powerResults{rIdx,fIdx,3}(c);
                    count = count + 1;
                end
            end
            fprintf(fp, ';%f', sumPower/count); % Average power per region
        end
        fprintf(fp,'\n');
    end
    fclose(fp);
end

fclose all;
disp('PROCESSING COMPLETE');
