% VideoTracker - Interface with Cheetah Acquisition Entity.
% VideoTracker methods:
%   getData - return struct with data fields available for the acquisition entity.

% 2011-12-14. Leonardo Molina.
% 2018-08-13. Last modified.
classdef VideoTracker < CheetahWrapper.Stream
    methods
        function obj = VideoTracker(name, cheetah)
            obj = obj@CheetahWrapper.Stream(name, cheetah);
        end
        
        function data = getData(obj)
            % CheetahWrapper.VideoTracker.getData()
            % Return struct with data fields available for the acquisition entity.
            
            % Get buffer sizes from NetCom DLL.
            bufferSize = calllib('MatlabNetComClient', 'GetRecordBufferSize');
            
            % Clear out all of the return values and preallocate space for the variables.
            data.timestampArray = zeros(1, bufferSize);
            data.extractedLocationArray = zeros(1, 2 * bufferSize);
            data.extractedAngleArray = zeros(1, bufferSize);
            data.numRecordsReturned = 0;
            data.numRecordsDropped = 0;
            
            % Setup the ref pointers for the function call.
            timestampArrayPtr = libpointer('int64PtrPtr', data.timestampArray);
            extractedLocationArrayPtr = libpointer('int32PtrPtr', data.extractedLocationArray);
            extractedAngleArrayPtr = libpointer('int32PtrPtr', data.extractedAngleArray);
            numRecordsReturnedPtr = libpointer('int32Ptr', data.numRecordsReturned);
            numRecordsDroppedPtr = libpointer('int32Ptr', data.numRecordsDropped);
            [~, ~, data.timestampArray, data.extractedLocationArray, data.extractedAngleArray, data.numRecordsReturned, data.numRecordsDropped] = calllib('MatlabNetComClient', 'GetNewVTData', obj.name, timestampArrayPtr, extractedLocationArrayPtr, extractedAngleArrayPtr, numRecordsReturnedPtr, numRecordsDroppedPtr);
            data.streamName = obj.name;
            
            % Format the return arrays.
            if data.numRecordsReturned > 0
                % Truncate arrays to the number of returned records.
                data.timestampArray = data.timestampArray(1:data.numRecordsReturned);
                data.extractedLocationArray = data.extractedLocationArray(1:2 * data.numRecordsReturned);
                data.extractedAngleArray = data.extractedAngleArray(1:data.numRecordsReturned);
            else
                % Return empty arrays if no data was retrieved.
                data.timestampArray = [];
                data.extractedLocationArray = [];
                data.extractedAngleArray = [];
            end		
        end
    end
end