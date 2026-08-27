% Script to import, preprocess, and save EEG datasets with channel location setup
clear all;
tic;  % Start timer

% Define directories (customize dataDir for your Windows environment)
dataDir   = 'C:\path\to\edf_files';
outputDir = fullfile(dataDir, 'SET');
scriptDir = fileparts(mfilename('fullpath'));
chanLocs  = fullfile(scriptDir, 'standard_1005.elc');

if ~isfolder(dataDir)
    error('Input directory not found: %s. Update dataDir before running the script.', dataDir);
end

if ~isfile(chanLocs)
    error('Channel-location file not found: %s', chanLocs);
end

if exist('pop_biosig', 'file') ~= 2
    error('pop_biosig was not found. Install or enable the EEGLAB BIOSIG plugin.');
end

% Create output folder if it does not exist
if ~exist(outputDir, 'dir')
    mkdir(outputDir);
end

% List all EDF files in the data directory
edfFiles = dir(fullfile(dataDir, '*.edf'));
nFiles   = numel(edfFiles);

if nFiles == 0
    error('No EDF files were found in: %s', dataDir);
end

% Loop through each EDF file
for i = 1:nFiles
    filename = edfFiles(i).name;
    [~, baseName] = fileparts(filename);
    outputFilename = [baseName '.set'];
    fprintf('Processing %s\n', filename);
    
    % Load EDF file without importing events or annotations
    EEG = pop_biosig(fullfile(dataDir, filename), ...
                     'importevent', 'off', ...
                     'blockepoch',  'off', ...
                     'importannot', 'off');
                 
    % Remove non-EEG channels by name
    EEG = pop_select(EEG, 'nochannel', { ...
        'M1','M2','Cb2','Cb1','VEOG','HEOG','EMG','EKG', ...
        'Fz','FT11','F11','F12','FT12','Status' ...
    });
    
    % Apply bandpass filter from 0.5 to 50 Hz
    EEG = pop_eegfiltnew(EEG, 'locutoff', 0.5, 'hicutoff', 50);
    
    % Assign standard 10-05 channel locations
    EEG = pop_chanedit(EEG, 'lookup', chanLocs);
    
    % Run ICA with PCA reduction to 55 components
    EEG = pop_runica(EEG, ...
        'icatype',   'runica', ...
        'extended',  1, ...
        'interrupt', 'on', ...
        'pca',       55 ...
    );
    
    % Remove the first four independent components
    EEG = pop_subcomp(EEG, [1 2 3 4], 0);
    
    % Check dataset consistency
    EEG = eeg_checkset(EEG);
    
    % Save the dataset in EEGLAB .set format
    pop_saveset(EEG, ...
        'filename', outputFilename, ...
        'filepath', outputDir ...
    );
end

% Report total execution time
elapsedTime = toc;             % Total time in seconds
fprintf('Total execution time: %.2f minutes\n', elapsedTime/60);
fprintf('Processing complete.\n');
