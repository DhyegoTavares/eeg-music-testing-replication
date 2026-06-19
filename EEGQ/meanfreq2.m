function spec = meanfreq2(fmin, fmax, chanArray, frames, epochs, srate, dataMatrix)
% meanfreq computes the mean spectral power within a frequency band
%
% Inputs:
%   fmin        - lower frequency bound (Hz)
%   fmax        - upper frequency bound (Hz)
%   chanArray   - vector of channel indices to analyze
%   frames      - number of time samples per epoch
%   epochs      - total number of epochs in the data
%   srate       - sampling rate of the data (Hz)
%   dataMatrix  - matrix of raw EEG data (channels × total samples)
%
% Output:
%   spec        - vector of mean log-power values for each channel (dB)

    % Number of channels to process
    nChannels = length(chanArray);
    
    % Preallocate a 2D array: channels × total samples
    data = zeros(nChannels, frames * epochs);

    % Extract and organize the requested channels into 'data'
    for k = 1:nChannels
        data(k, :) = dataMatrix(chanArray(k), :);
    end

    % Determine FFT length as the next lower power of two
    fftLength = 2^floor(log(frames)/log(2));
    
    % Initialize matrix for storing power spectra
    halfFreqBins = fftLength / 2;
    spectra = zeros(nChannels, epochs * halfFreqBins);
    
    % Conversion factor from power to decibels
    dB = 10 / log(10);

    % Frequency band of interest
    freqLimits = [fmin, fmax];

    % Loop over epochs and channels to compute Welch power spectral density
    for e = 1:epochs
        for ch = 1:nChannels
            segment = data(ch, (e-1)*frames+1 : e*frames);
            [Pxx, freqs] = pwelch(segment, [], [], fftLength, srate);
            spectra(ch, (e-1)*halfFreqBins+1 : e*halfFreqBins) = Pxx(1:halfFreqBins)';
        end
    end

    % Extract frequency vector and find indices within the desired band
    freqBandIdx = find(freqs(1:halfFreqBins) >= freqLimits(1) & freqs(1:halfFreqBins) <= freqLimits(2));
    nFreqs = length(freqBandIdx);

    % Compute log-scaled spectra (dB) for the selected band
    logSpectra = zeros(nChannels, nFreqs * epochs);
    for e = 1:epochs
        idxRange = (e-1)*nFreqs + (1:nFreqs);
        logSpectra(:, idxRange) = dB * log(spectra(:, (e-1)*halfFreqBins + freqBandIdx));
    end

    % Average log-power across the nFreqs frequency bins for each epoch
    logSpectra = reshape(mean(reshape(logSpectra, nChannels, nFreqs, epochs), 2), nChannels, epochs);

    % Compute the mean log-power across epochs for each channel
    if size(logSpectra, 2) > 1
        spec = mean(logSpectra, 2)';
    else
        spec = logSpectra;
    end

    % Optional: Plot the resulting spectrum
    % plot(spec');
end
