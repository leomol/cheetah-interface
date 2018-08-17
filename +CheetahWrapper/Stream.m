% CheetahWrapper.Stream - Common methods on a Cheetah acquisition entity.

% 2011-12-14. Leonardo Molina.
% 2018-08-13. Last modified.
classdef Stream < handle
    properties (SetAccess = private)
        % name - The tag name assigned to this object.
        name
        
        % cheetah - Cheetah object.
        cheetah
    end
    
    methods
        function obj = Stream(name, cheetah)
            % obj = CheetahWrapper.Stream(name, cheetah)
            % Create an acquisition entity with the given name.
            
            obj.name = name;
            obj.cheetah = cheetah;
            if obj.cheetah.connected
                success = calllib('MatlabNetComClient', 'OpenStream', name);
            else
                success = false;
            end
            if ~success
                error('Cheetah not connected.');
            end
        end
        
        function delete(obj)
            % CheetahWrapper.Stream.delete()
            % Close the stream associated to this object.
            
            if obj.cheetah.connected
                calllib('MatlabNetComClient', 'CloseStream', obj.name);
            end
        end
    end
end