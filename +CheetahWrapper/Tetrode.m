% Tetrode - Interface with Cheetah Acquisition Entity.
% Tetrode methods:
%   getData - return struct with data fields available for the acquisition entity.

% 2011-12-14. Leonardo Molina.
% 2019-10-05. Last modified.
classdef Tetrode < CheetahWrapper.Stream & CheetahWrapper.WaveformTemplate
    methods
        function obj = Tetrode(name, cheetah)
            obj = obj@CheetahWrapper.Stream(name, cheetah);
            obj = obj@CheetahWrapper.WaveformTemplate(name, cheetah);
        end
        
        function [spikes, dropped] = getData(obj)
            % CheetahWrapper.Tetrode.getData()
            % Return struct with data fields available for the acquisition entity.
            
            
            % Get buffer sizes from NetCom DLL.
            bufferSize = calllib('MatlabNetComClient', 'GetRecordBufferSize');
            spikeSampleWindowSize = calllib('MatlabNetComClient', 'GetSpikeSampleWindowSize');
            maxSpikeFeatures = calllib('MatlabNetComClient', 'GetMaxSpikeFeatures');
            % Number of subchannels in a tetrode.
            numSubChannels = 4;

            % Clear out all of the return values and preallocate space for the variables.
            dataArray = zeros(1, numSubChannels * spikeSampleWindowSize * bufferSize);
            timestampArray = zeros(1, bufferSize);
            spikeChannelNumberArray = zeros(1, bufferSize);
            cellNumberArray = zeros(1, bufferSize);
            featureArray = zeros(1, maxSpikeFeatures * bufferSize);
            numRecordsReturned = 0;
            numRecordsDropped = 0;
            
            % Setup the ref pointers for the function call.
            dataArrayPtr = libpointer('int16PtrPtr', dataArray);
            timestampArrayPtr = libpointer('int64PtrPtr', timestampArray);
            spikeChannelNumberArrayPtr = libpointer('int32PtrPtr', spikeChannelNumberArray);
            cellNumberArrayPtr = libpointer('int32PtrPtr', cellNumberArray);
            featureArrayPtr = libpointer('int32PtrPtr', featureArray);
            numRecordsReturnedPtr = libpointer('int32Ptr', numRecordsReturned);
            numRecordsDroppedPtr = libpointer('int32Ptr', numRecordsDropped);
            [~, ~, timestampArray, spikeChannelNumberArray, cellNumberArray, featureArray, dataArray, numRecordsReturned, numRecordsDropped] = calllib('MatlabNetComClient', 'GetNewTTData', obj.name, timestampArrayPtr, spikeChannelNumberArrayPtr, cellNumberArrayPtr, featureArrayPtr, dataArrayPtr, numRecordsReturnedPtr, numRecordsDroppedPtr);

            % Format the return arrays.
            if numRecordsReturned > 0
                % Truncate arrays to the number of returned records.
                dataArray = dataArray(1:numRecordsReturned * spikeSampleWindowSize * numSubChannels);
                dataArray = reshape(dataArray, numSubChannels, spikeSampleWindowSize, numRecordsReturned);
                dataArray = arrayfun(@(i) dataArray(:, :, i), 1:size(dataArray, 3), 'UniformOutput', false);
                timestampArray = timestampArray(1:numRecordsReturned);
                spikeChannelNumberArray = spikeChannelNumberArray(1:numRecordsReturned);
                cellNumberArray = cellNumberArray(1:numRecordsReturned);
                featureArray = featureArray(1:numRecordsReturned * maxSpikeFeatures);
                featureArray = reshape(featureArray, maxSpikeFeatures, numRecordsReturned);
                spikes = struct('waveform', dataArray, 'timestamp', num2cell(timestampArray), 'id', num2cell(cellNumberArray), 'channel', num2cell(spikeChannelNumberArray), 'features', num2cell(featureArray, 1));
            else
                % Return empty arrays if no data was retrieved.
                spikes = struct('waveform', {}, 'timestamp', {}, 'id', {}, 'channel', {}, 'features', {}); % !!
            end
            dropped = numRecordsDropped;
        end
    end
end