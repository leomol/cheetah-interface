% ContinuoslySampled - Interface with Cheetah Acquisition Entity.
% ContinuoslySampled methods:
%   getData - return struct with data fields available for the acquisition entity.

% 2011-12-14. Leonardo Molina.
% 2018-08-13. Last modified.
classdef ContinuoslySampled < CheetahWrapper.Stream
    methods
        function obj = ContinuoslySampled(name, cheetah)
            obj = obj@CheetahWrapper.Stream(name, cheetah);
        end
        
        function data = getData(obj)
            % CheetahWrapper.ContinouslySampled.getData()
            % Return struct with data fields available for the acquisition entity.
            
            % Get buffer sizes from NetCom DLL.get buffer sizes from NetCom DLL.
            bufferSize = calllib('MatlabNetComClient', 'GetRecordBufferSize');
            maxSamples = calllib('MatlabNetComClient', 'GetMaxCSCSamples');

            % Clear out all of the return values and preallocate space for the variables.
            data.dataArray = zeros(1, maxSamples * bufferSize);
            data.timestampArray = zeros(1, bufferSize);
            data.channelNumberArray = zeros(1, bufferSize);
            data.samplingFreqArray = zeros(1, bufferSize);
            data.numValidSamplesArray = zeros(1, bufferSize);
            data.numRecordsReturned = 0;
            data.numRecordsDropped = 0;
            
            % Setup the pointers for the function call.
            dataArrayPtr = libpointer('int16PtrPtr', data.dataArray);
            timestampArrayPtr = libpointer('int64PtrPtr', data.timestampArray);
            channelNumberArrayPtr = libpointer('int32PtrPtr', data.channelNumberArray);
            samplingFreqArrayPtr = libpointer('int32PtrPtr', data.samplingFreqArray);
            numValidSamplesArrayPtr = libpointer('int32PtrPtr', data.numValidSamplesArray);
            numRecordsReturnedPtr = libpointer('int32Ptr', data.numRecordsReturned);
            numRecordsDroppedPtr = libpointer('int32Ptr', data.numRecordsDropped);
            [~, ~, data.timestampArray, data.channelNumberArray, data.samplingFreqArray, data.numValidSamplesArray, data.dataArray, data.numRecordsReturned, data.numRecordsDropped] = calllib('MatlabNetComClient', 'GetNewCSCData', obj.name, timestampArrayPtr, channelNumberArrayPtr, samplingFreqArrayPtr, numValidSamplesArrayPtr, dataArrayPtr, numRecordsReturnedPtr, numRecordsDroppedPtr);
            data.streamName = obj.name;
            
            % Format the return arrays.
            if data.numRecordsReturned > 0
                % Truncate arrays to the number of returned records.
                data.dataArray = data.dataArray(1:data.numRecordsReturned * maxSamples);
                data.timestampArray = data.timestampArray(1:data.numRecordsReturned);
                data.channelNumberArray = data.channelNumberArray(1:data.numRecordsReturned);
                data.samplingFreqArray = data.samplingFreqArray(1:data.numRecordsReturned);
                data.numValidSamplesArray = data.numValidSamplesArray(1:data.numRecordsReturned);
            else
                % Return empty arrays if no data was retrieved.
                data.dataArray = [];
                data.timestampArray = [];
                data.channelNumberArray = [];
                data.samplingFreqArray = [];
                data.numValidSamplesArray = [];
            end
        end
    end
end