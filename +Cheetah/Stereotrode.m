classdef Stereotrode < Cheetah.Object
    methods
        function obj = Stereotrode(name)
            obj = obj@Cheetah.Object(name);
        end
        
        function data = getData(obj)
            % Get buffer sizes from NetCom DLL.
            bufferSize = calllib('MatlabNetComClient', 'GetRecordBufferSize');
            spikeSampleWindowSize = calllib('MatlabNetComClient', 'GetSpikeSampleWindowSize');
            maxSpikeFeatures = calllib('MatlabNetComClient', 'GetMaxSpikeFeatures');
            % Number of stereotrode channels.
            numSubChannels = 2;
            
            % Clear out all of the return values and preallocate space for the variables.
            data.dataArray = zeros(1, numSubChannels * spikeSampleWindowSize * bufferSize);
            data.timeStampArray = zeros(1, bufferSize);
            data.spikeChannelNumberArray = zeros(1, bufferSize);
            data.cellNumberArray = zeros(1, bufferSize);
            data.featureArray = zeros(1, maxSpikeFeatures * bufferSize);
            data.numRecordsReturned = 0;
            data.numRecordsDropped = 0;
            
            % Setup the ref pointers for the function call.
            dataArrayPtr = libpointer('int16PtrPtr', data.dataArray);
            timeStampArrayPtr = libpointer('int64PtrPtr', data.timeStampArray);
            spikeChannelNumberArrayPtr = libpointer('int32PtrPtr', data.spikeChannelNumberArray);
            cellNumberArrayPtr = libpointer('int32PtrPtr', data.cellNumberArray);
            featureArrayPtr = libpointer('int32PtrPtr', data.featureArray);
            numRecordsReturnedPtr = libpointer('int32Ptr', data.numRecordsReturned);
            numRecordsDroppedPtr = libpointer('int32Ptr', data.numRecordsDropped);
            [~, ~, data.timeStampArray, data.spikeChannelNumberArray, data.cellNumberArray, data.featureArray, data.dataArray, data.numRecordsReturned, data.numRecordsDropped] = calllib('MatlabNetComClient', 'GetNewSTData', obj.name, timeStampArrayPtr, spikeChannelNumberArrayPtr, cellNumberArrayPtr, featureArrayPtr, dataArrayPtr, numRecordsReturnedPtr, numRecordsDroppedPtr);
            data.objectName = obj.name;

            % Format the return arrays.
            if data.numRecordsReturned > 0
                % Truncate arrays to the number of returned records.
                data.dataArray = data.dataArray(1:data.numRecordsReturned * spikeSampleWindowSize * numSubChannels);
                data.timeStampArray = data.timeStampArray(1:data.numRecordsReturned);
                data.spikeChannelNumberArray = data.spikeChannelNumberArray(1:data.numRecordsReturned);
                data.cellNumberArray = data.cellNumberArray(1:data.numRecordsReturned);
                data.featureArray = data.featureArray(1:data.numRecordsReturned * maxSpikeFeatures);
            else
                % Return empty arrays if no data was retrieved.
                data.dataArray = [];
                data.timeStampArray = [];
                data.spikeChannelNumberArray = [];
                data.cellNumberArray = [];
                data.featureArray = [];
            end	
        end
    end
end