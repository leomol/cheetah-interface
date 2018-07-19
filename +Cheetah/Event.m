classdef Event < Cheetah.Object
    methods
        function obj = Event(name)
            obj = obj@Cheetah.Object(name);
        end
        
        function data = getData(obj)
            % Get buffer sizes from NetCom DLL.
            bufferSize = calllib('MatlabNetComClient', 'GetRecordBufferSize');
            maxStringLength = calllib('MatlabNetComClient', 'GetMaxEventStringLength');
            % Ensures enough space is allocated for each event string name.
            placeholder = blanks(maxStringLength);

            % Clear out all of the return values and preallocate space for the variables.
            data.timeStampArray = zeros(1, bufferSize);
            data.eventIDArray = zeros(1, bufferSize);
            data.ttlValueArray = zeros(1, bufferSize);
            data.stringArray = repmat({placeholder}, 1, bufferSize);
            data.numRecordsDropped = 0;
            data.numRecordsReturned = 0;
            
            % Setup the ref pointers for the function call.
            timeStampArrayPtr = libpointer('int64PtrPtr', data.timeStampArray);
            eventIDArrayPtr = libpointer('int32PtrPtr', data.eventIDArray);
            ttlValueArrayPtr = libpointer('int32PtrPtr', data.ttlValueArray);
            eventStringArrayPtr = libpointer('stringPtrPtr', data.stringArray);
            numRecordsReturnedPtr = libpointer('int32Ptr', data.numRecordsReturned);
            numRecordsDroppedPtr = libpointer('int32Ptr', data.numRecordsDropped);
            [~, ~, data.timeStampArray, data.eventIDArray, data.ttlValueArray, data.stringArray, data.numRecordsReturned, data.numRecordsDropped] = calllib('MatlabNetComClient', 'GetNewEventData', obj.name, timeStampArrayPtr, eventIDArrayPtr, ttlValueArrayPtr, eventStringArrayPtr, numRecordsReturnedPtr, numRecordsDroppedPtr);
            data.objectName = obj.name;
            
            % Format the return arrays.
            if data.numRecordsReturned > 0
                % Truncate arrays to the number of returned records.
                data.timeStampArray = data.timeStampArray(1:data.numRecordsReturned);
                data.eventIDArray = data.eventIDArray(1:data.numRecordsReturned);
                data.ttlValueArray = data.ttlValueArray(1:data.numRecordsReturned);
                data.stringArray = data.stringArray(1:data.numRecordsReturned);
            else
                % Return empty arrays if no data was retrieved.
                data.timeStampArray = [];
                data.eventIDArray = [];
                data.ttlValueArray = [];
                data.stringArray = [];
            end
        end
    end
end