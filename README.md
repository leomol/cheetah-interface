# Cheetah interface library
MATLAB classes to interact with Cheetah Acquisition System from [Neuralynx][Neuralynx] during a recording session.
This library and Cheetah Acquisition Software may run in the same or in different computers. The downside of running in the same computer is that your analysis scripts may take up resources needed for data acquisition. The downside of running in different computers is the delay introduced by the network communication.

## Prerequisites
* [MATLAB][MATLAB] (last tested with R2018a)
* [Cheetah][Cheetah]
* [NetComDevelopmentPackage][NetComPartial] but can also be downloaded from [Neuralynx][NetComFull]
* Windows 10, 64Bit (32 bit version not tested).

## Installation
* Download library from repository and place the MATLAB folder under Documents folder.
* Create/modify Documents/MATLAB/startup.m and put `addpath(NetComDevelopmentPackage_v3.1.0\MATLAB_M-files');`
* Make sure MATLAB is enabled in Window's firewall. Normally a popup will come up during the first connection.

## Example using `Cheetah.m`:
```matlab
	cd('examples')
	plotTetrodeStream();
```

## Version History
### 0.1.0
* Initial Release: Library and example code

## License
© 2018 [Leonardo Molina][Leonardo Molina]

This project is licensed under the [GNU GPLv3 License][LICENSE.md].

[Leonardo Molina]: https://github.com/leomol
[MATLAB]: https://www.mathworks.com/downloads/
[Cheetah]: https://neuralynx.com/software/category/development
[NetComPartial]: NetComDevelopmentPackage_v3
[NetComFull]: https://neuralynx.com/software/category/development
[Neuralynx]: https://neuralynx.com
[LICENSE.md]: LICENSE.md