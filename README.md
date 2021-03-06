# Cheetah interface
MATLAB classes to interact with Cheetah Acquisition System from [Neuralynx][Neuralynx] during a recording session. Examples provided to use neuronal spiking activity to trigger closed-loop stimulation in neurophysiological experiments.

A typical experiment consists of:
* Recording 5-10 minutes of spiking data
* Spike sorting and creating neuronal templates
* Acquiring more data to reinforce occurrences of selected neuronal state vectors in a feedback loop.
[![Spike stream demo](cheetah-wrapper-demo.png)](https://drive.google.com/file/d/1APbzi_oyghasV6WPbA7SeP0WfSWiig0g)

## Prerequisites
* [MATLAB][MATLAB] (last tested with R2018a)
* [Cheetah][Cheetah]
* [SpikeSort3D][SpikeSort3D] (optional)
* [NetComDevelopmentPackage][NetComFull] (dependencies already included but can also be downloaded from [Neuralynx][NetComFull])
* Windows 10, 64Bit (32 bit version not tested).

## Installation
* Install MATLAB, Cheetah and SpikeSort 3D.
* Make sure MATLAB is enabled in Window's firewall. Normally a pop-up will come up during the first connection.
* Download and extract this library to Documents/MATLAB folder.

## Example 1 - closed-loop stimulation in neurophysiological experiments:
* Record a few minutes of spiking data with Cheetah.
* Stop acquisition and sort data with KlustaKwik (e.g. via SpikeSort 3D).
* Start acquisition in Cheetah and run `ClosedLoop()` in MATLAB.
* Load an acquisition entity (e.g. TT1)
* Create a neuronal pattern by selecting a subset of neurons.
* Define the required number of coactive neurons in a given time window.
* Click on `Send`.
![Spike stream demo](selection-window.png)

## Example 2 - plot spikes from a tetrode:
* Record a few minutes of spiking data with Cheetah.
* Stop acquisition and sort data with KlustaKwik (e.g. via SpikeSort 3D)
* Start acquisition in Cheetah and run the commands below, replacing `TT1` for an existing acquisition entity name:
```matlab
	% Define acquisition entity name, waveform file, and cluster file.
	streamName = 'TT1';
	waveformFile = 'TT1.nse';
	clusterFile = 'TT1.clu.1';
	
	% Detect neuronal activation.
	ids = 1:10;
	count = 2;
	window = 0.200;
	
	% Interface with Cheetah.
	cheetah = CheetahWrapper();

	% Get acquisition stream.
	stream = cheetah.getStream(streamName);

	% Send cluster definition to Cheetah.
	stream.send(waveformFile, clusterFile);

	% Produce a default stimulus when the given neuronal ensemble activates.
	stimulationFunction = @() tone(2250, 0.1);
	patternTrigger(stream, ids count, window, stimulationFunction);
```

## Example 3 - list all acquisition entities loaded in the configuration file:
```matlab
	cheetah = CheetahWrapper();
	streams = obj.getStreams();
	for i = 1:numel(streams)
		stream = streams{i};
		disp(stream.name);
	end
```

## Example 4 - display acquisition time from one of the stream objects:
```matlab
	cheetah = CheetahWrapper();
	streams = obj.getStreams();
	while true
		data = streams{1}.getData();
		fprintf('Cheetah time= %.2f\n', data.timeStampArray(end));
	end
```
## Notes
This library and Cheetah Acquisition Software may run in the same or in different computers.

The downside of running both programs in the same computer is that your analysis scripts may take up resources needed for data acquisition. The downside of running both programs in different computers is the delay introduced by the network communication.

## Version History
### 0.1.2
* Demo script has a selection window for activity patterns.
* Demo script has been tested for latencies (< 15ms).
* Demo script now triggers based on ensemble activity.
* Test function takes an arbitrary stimulation function as input.
### 0.1.0
* Initial Release: Library and example code

## License
© 2019 [Leonardo Molina][Leonardo Molina]

This project is licensed under the [GNU GPLv3 License][LICENSE.md].

[Leonardo Molina]: https://github.com/leomol
[MATLAB]: https://www.mathworks.com/downloads/
[Cheetah]: https://neuralynx.com/
[SpikeSort3D]: https://neuralynx.com/software/spikesort-3d
[NetComFull]: https://neuralynx.com/software/category/development
[Neuralynx]: https://neuralynx.com
[LICENSE.md]: LICENSE.md