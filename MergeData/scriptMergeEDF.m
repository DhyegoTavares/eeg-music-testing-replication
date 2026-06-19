% Clear workspace, close all figures, and clear the command window
clear;
close all;
clc;

% (Optional) Add EEGLAB to MATLAB path if it isn’t already
% eeglabPath = 'path/to/eeglab';
% addpath(eeglabPath);

% Launch EEGLAB
eeglab;

% Define the folder containing your EDF files
dataDir = 'C:\path\to\edf_files\session007\';  % Update to your folder

% Get a list of all .edf files in that folder
edfFiles = dir(fullfile(dataDir, '*.edf'));
numFiles = numel(edfFiles);

% Ensure there are at least two files to merge
if numFiles < 2
    error('At least two .edf files are required for merging.');
end

% Load the first EDF file
EEG = pop_biosig(fullfile(dataDir, edfFiles(1).name));

% Loop through the remaining EDF files and merge them
for i = 2:numFiles
    fprintf('Merging file %d of %d: %s\n', i, numFiles, edfFiles(i).name);
    EEG_tmp = pop_biosig(fullfile(dataDir, edfFiles(i).name));
    EEG = pop_mergeset(EEG, EEG_tmp, 1);
end

% Save the merged dataset back to EDF format
outputFile = fullfile(dataDir, 'merged_session007.edf');  % Rename as needed
pop_writeeeg(EEG, outputFile, 'TYPE', 'EDF');

disp('EDF files successfully merged and saved.');
