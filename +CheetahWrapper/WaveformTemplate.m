% CheetahWrapper.WaveformTemplate - Send cluster definitions from files.

% 2011-12-14. Leonardo Molina.
% 2018-08-13. Last modified.
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
        
        function match = send(obj, var1, var2)
            % CheetahWrapper.WaveformTemplate.send(spikeFile, clusterFile)
            % 
            % WaveformTemplate.send(clusterId, limits)
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
                % waveforms: 32 x 4* x n
                waveforms = Nlx2MatSpike(spikeFile, [0 0 0 0 1], 0, 1, []);
                [~, ~, ext] = fileparts(clusterFile);
                if strcmpi(ext, '.clusters')
                    tmp = load(clusterFile, '-mat');
                    idMap = zeros(0, 0);
                    for k = 1:numel(tmp.MClust_Clusters)
                        idMap(tmp.MClust_Clusters{k}.myPoints) = k;
                    end
                else
                    fid = fopen(clusterFile, 'r');
                    idMap = textscan(fid, '%f', 'CollectOutput', true, 'CommentStyle', '%');
                    idMap = idMap{1};
                    fclose(fid);
                end
                
                nSpikes = size(waveforms, 3);
                nClustered = numel(idMap);
                if nSpikes == nClustered
                    match = true;
                elseif nClustered > nSpikes
                    idMap = idMap(1:nSpikes);
                    match = false;
                else
                    waveforms = waveforms(:, :, 1:nClustered);
                    match = false;
                end
                
                uids = unique(idMap(:)');
                for id = uids
                    k = idMap == id;
                    av = mean(waveforms(:, :, k), 3);
                    sd = std(waveforms(:, :, k), [], 3);
                    av = permute(av, [3, 1, 2]);
                    sd = permute(sd, [3, 1, 2]);
                    limits = [av - sd; av + sd];
                    obj.send(id, limits);
                end
            end
        end
        
        function clear(obj)
            obj.cheetah.send(sprintf('-ClearClusters %s\n', obj.name));
        end
        
        function delete(obj)
            obj.clear();
        end
    end
end