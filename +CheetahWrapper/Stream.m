% CheetahWrapper.Stream - Common methods on a Cheetah acquisition entity.

% 2011-12-14. Leonardo Molina.
% 2019-10-04. Last modified.
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
            if ~obj.cheetah.openStream(name)
                error('Cheetah not connected.');
            end
        end
        
        function delete(obj)
            % CheetahWrapper.Stream.delete()
            % Close the stream associated to this object.
            if isobject(obj.cheetah)
                obj.cheetah.closeStream(obj.name);
            end
        end
    end
end