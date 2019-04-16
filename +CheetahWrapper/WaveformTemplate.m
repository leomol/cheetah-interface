% CheetahWrapper.WaveformTemplate - Send cluster definitions from files.

% 2011-12-14. Leonardo Molina.
% 2019-04-10. Last modified.
classdef WaveformTemplate < handle
    properties (Access = private)
        cheetah
        name
    end
    
    methods
        function obj = WaveformTemplate(name, cheetah)
            obj.name = name;
            obj.cheetah = cheetah;
        end
        
        function send(obj, var1, var2)
            % CheetahWrapper.WaveformTemplate.send(spikeFile, clusterFile)
            % 
            % CheetahWrapper.WaveformTemplate.send(clusterId, limits)
            % where limits is a 2 x 32 matrix x n of min and max values
            % delimiting spike waveforms with 32 points.
            % [min1, min2, ..., min32
            %  max1, max2, ..., max32]
            % n changes according to the number of channels in the acquisition
            % entity. For example, limits is a 2 x 32 x 4 matrix where 2 x 32 
            % waveform limits are provided for each of the 4 channels.
            
            if isnumeric(var1)
                clusterId = var1;
                limits = round(var2);
                limits = flipud(limits);
                nChannels = size(limits, 3);
                for channel = 1:nChannels
                    limitsText = strtrim(sprintf('%i ', limits(:, :, channel)));
                    % -SetClusterBoundary <Acquisition entity name> <cell
                    % number> <boundary type> <values>
                    obj.cheetah.send(sprintf('-SetClusterBoundary %s %i "Template %i %s\n"', obj.name, clusterId, channel - 1, limitsText));
                end
            else
                spikeFile = var1;
                clusterFile = var2;
                [~, waveformLimits] = CheetahWrapper.getWaveforms(spikeFile, clusterFile);
                for id = waveformLimits.keys
                    obj.send(id, waveformLimits);
                end
            end
        end
        
        function clear(obj)
            if isobject(obj.cheetah)
                obj.cheetah.send(sprintf('-ClearClusters %s\n', obj.name));
            end
        end
        
        function delete(obj)
            obj.clear();
        end
    end
end