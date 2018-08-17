% 2018-08-16. Leonardo Molina.
% 2018-08-16. Last modified.

% Interface with Cheetah.
cheetah = CheetahWrapper();

% Get the electrode stream.
electrode = cheetah.getStream('TT1');

% Send the cluster definition to Cheetah.
nseFile = 'TT1.nse';
clusterFile = 'TT1.clu.1';
electrode.send(nseFile, clusterFile);

% Detect neuronal activation. Beep whenever a spike matches the target.
target = 7;
spikeTrigger(electrode, target);