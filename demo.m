% 2018-08-16. Leonardo Molina.
% 2019-02-07. Last modified.

% Define acquisition entity name, waveform file, and cluster file.
streamName = 'TT1';
waveformFile = 'TT1.nse';
clusterFile = 'TT1.clu.1';

% Detect ensemble activity. Beep whenever a spike matches the target.
ids = 1:10;
count = 2;
window = 0.200;

% Interface with Cheetah.
cheetah = CheetahWrapper();

% Get the electrode stream.
electrode = cheetah.getStream(streamName);

% Send the cluster definition to Cheetah.
electrode.send(waveformFile, clusterFile);

% Produce a default stimulus when the given neuronal ensemble activates.
patternTrigger(electrode, ids, count, window);