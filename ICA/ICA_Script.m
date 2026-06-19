% Script to import, preprocess, and save EEG datasets with channel location setup
clear all;
tic;  % Start timer

% Define directories (customize these paths as needed)
dataDir   = 'C:\path\to\edf_files\';    % Directory containing .edf files (include trailing slash)
outputDir = fullfile(dataDir, 'SET\');  % Directory to save processed .set files
chanLocs  = 'standard_1005.elc';        % Channel location file (in MATLAB path or full path)

% Create output folder if it does not exist
if ~exist(outputDir, 'dir')
    mkdir(outputDir);
end

% List all EDF files in the data directory
edfFiles = dir(fullfile(dataDir, '*.edf'));
nFiles   = numel(edfFiles);

% Loop through each EDF file
for i = 1:nFiles
    filename = edfFiles(i).name;
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
        'filename', filename, ...
        'filepath', outputDir ...
    );
end

% Report total execution time
elapsedTime = toc;             % Total time in seconds
fprintf('Total execution time: %.2f minutes\n', elapsedTime/60);
fprintf('Processing complete.\n');
