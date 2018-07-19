% Cheetah.Object - Common methods on a Cheetah acquisition object.

% 2011-12-14. Leonardo Molina.
% 2018-07-19. Last modified.
classdef Object < handle
    properties (Access = protected)
        % name - The tag name assigned to this object.
        name
    end
    
    methods
        function obj = Object(name)
            % obj = Cheetah.Object(name)
            % Create an object with the given name if a connection has been
            % previously stablished.
            
            if libisloaded('MatlabNetComClient') && calllib('MatlabNetComClient', 'AreWeConnected')
                obj.name = name;
            else
                error('Cannot open stream.');
            end
        end
        
        function delete(obj)
            % Cheetah.Object.delete()
            % Close the stream associated to this object.
            
            if libisloaded('MatlabNetComClient')
                calllib('MatlabNetComClient', 'CloseStream', obj.name);
            end
        end
    end
end