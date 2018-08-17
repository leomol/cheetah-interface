# Cheetah wrapper
MATLAB classes to interact with Cheetah Acquisition System from [Neuralynx][Neuralynx] during a recording session.
This library and Cheetah Acquisition Software may run in the same or in different computers.

## Prerequisites
* [MATLAB][MATLAB] (last tested with R2018a)
* [Cheetah][Cheetah]
* [SpikeSort3D][SpikeSort3D] (optional)
* [NetComDevelopmentPackage][NetComPartial] (already included but can also be downloaded from [Neuralynx][NetComFull])
* Windows 10, 64Bit (32 bit version not tested).

## Installation
* Install MATLAB, Cheetah and SpikeSort 3D.
* Make sure MATLAB is enabled in Window's firewall. Normally a pop-up will come up during the first connection.
* Download and extract this library to Documents/MATLAB folder.

## Example 1 - plot spikes from a tetrode:
* Record a few minutes of spiking data with Cheetah (tetrode TT1 must be one of the acquisition entities).
* Stop acquisition and sort data with KlustaKwik (e.g. via SpikeSort 3D)
* Start acquisition in Cheetah and run:
```matlab
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
```

## Example 2 - list all acquisition entities loaded in the configuration file:
```matlab
	cheetah = CheetahWrapper();
	streams = obj.getStreams();
	for i = 1:numel(streams)
		stream = streams{i};
		disp(stream.name);
	end
```

## Example 3 - display acquisition time from one of the stream objects:
```matlab
	cheetah = CheetahWrapper();
	streams = obj.getStreams();
	while true
		data = streams{1}.getData();
		fprintf('Cheetah time= %.2f\n', data.timeStampArray(end));
	end
```
## Notes
The downside of running both programs in the same computer is that your analysis scripts may take up resources needed for data acquisition. The downside of running both programs in different computers is the delay introduced by the network communication.

## Version History
### 0.1.0
* Initial Release: Library and example code

## License
© 2018 [Leonardo Molina][Leonardo Molina]

This project is licensed under the [GNU GPLv3 License][LICENSE.md].

[Leonardo Molina]: https://github.com/leomol
[MATLAB]: https://www.mathworks.com/downloads/
[Cheetah]: https://neuralynx.com/
[SpikeSort3D]: https://neuralynx.com/software/spikesort-3d
[NetComPartial]: NetComDevelopmentPackage_v3.1.0
[NetComFull]: https://neuralynx.com/software/category/development
[Neuralynx]: https://neuralynx.com
[LICENSE.md]: LICENSE.md