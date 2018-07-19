classdef VideoTracker < Cheetah.Object
    methods
        function obj = VideoTracker(name)
            obj = obj@Cheetah.Object(name);
        end
        
        function data = getData(obj)
            % Get buffer sizes from NetCom DLL.
            bufferSize = calllib('MatlabNetComClient', 'GetRecordBufferSize');
            
            % Clear out all of the return values and preallocate space for the variables.
            data.timeStampArray = zeros(1, bufferSize);
            data.extractedLocationArray = zeros(1, 2 * bufferSize);
            data.extractedAngleArray = zeros(1, bufferSize);
            data.numRecordsReturned = 0;
            data.numRecordsDropped = 0;
            
            % Setup the ref pointers for the function call.
            timeStampArrayPtr = libpointer('int64PtrPtr', data.timeStampArray);
            extractedLocationArrayPtr = libpointer('int32PtrPtr', data.extractedLocationArray);
            extractedAngleArrayPtr = libpointer('int32PtrPtr', data.extractedAngleArray);
            numRecordsReturnedPtr = libpointer('int32Ptr', data.numRecordsReturned);
            numRecordsDroppedPtr = libpointer('int32Ptr', data.numRecordsDropped);
            [~, ~, data.timeStampArray, data.extractedLocationArray, data.extractedAngleArray, data.numRecordsReturned, data.numRecordsDropped] = calllib('MatlabNetComClient', 'GetNewVTData', obj.name, timeStampArrayPtr, extractedLocationArrayPtr, extractedAngleArrayPtr, numRecordsReturnedPtr, numRecordsDroppedPtr);
            data.objectName = obj.name;
            
            % Format the return arrays.
            if data.numRecordsReturned > 0
                % Truncate arrays to the number of returned records.
                data.timeStampArray = data.timeStampArray(1:data.numRecordsReturned);
                data.extractedLocationArray = data.extractedLocationArray(1:2 * data.numRecordsReturned);
                data.extractedAngleArray = data.extractedAngleArray(1:data.numRecordsReturned);
            else
                % Return empty arrays if no data was retrieved.
                data.timeStampArray = [];
                data.extractedLocationArray = [];
                data.extractedAngleArray = [];
            end		
        end
    end
end