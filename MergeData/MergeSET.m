% Clear the MATLAB environment
clear;          % Remove all variables from workspace
close all;      % Close all figure windows
clc;            % Clear the command window

% (Optional) Add EEGLAB to MATLAB path if not already on it
% eeglabPath = 'path/to/eeglab';  
% addpath(eeglabPath);

% Launch EEGLAB
eeglab;

% Define the folder containing your EEGLAB .set files
dataDir = 'path/to/your/set_files';  

% Get a list of all .set files in that folder
setFiles = dir(fullfile(dataDir, '*.set'));
numFiles = numel(setFiles);

% Ensure there are at least two files to merge
if numFiles < 2
    error('At least two .set files are required for merging.');
end

% Specify channel labels to remove (if present)
channelsToRemove = {'Status', 'trigger'};

% Load the first dataset
EEG = pop_loadset('filename', setFiles(1).name, ...
                  'filepath', dataDir);

% Remove unwanted channels from the first dataset
currentLabels = {EEG.chanlocs.labels};
idxRemove = find(ismember(lower(currentLabels), lower(channelsToRemove)));
if ~isempty(idxRemove)
    EEG = pop_select(EEG, 'nochannel', idxRemove);
end

% Loop through the remaining files and merge them
for i = 2:numFiles
    % Load the next dataset
    EEG_tmp = pop_loadset('filename', setFiles(i).name, ...
                         'filepath', dataDir);
    
    % Remove the same unwanted channels, if they exist
    tmpLabels = {EEG_tmp.chanlocs.labels};
    idxTmp = find(ismember(lower(tmpLabels), lower(channelsToRemove)));
    if ~isempty(idxTmp)
        EEG_tmp = pop_select(EEG_tmp, 'nochannel', idxTmp);
    end

    % Merge with the main EEG structure
    EEG = pop_mergeset(EEG, EEG_tmp, 1);
end

% Save the merged dataset
outputFilename = 'merged.set';
pop_saveset(EEG, 'filename', outputFilename, ...
                  'filepath', dataDir);

disp('All .set files have been successfully merged and saved.');
