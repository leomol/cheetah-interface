% Cheetah - Interface with Cheetah Acquisition System for realtime requests.

% 2011-12-14. Leonardo Molina.
% 2018-07-19. Last modified.
classdef Cheetah < handle
    properties (Access = private)
        % className - This class' name.
        className
        
        % server - The ip address or domain name of the computer hosting Cheetah.
        server
        
        % connected - Whether a connection has been stablished.
        connected = false
        
        % objects - List of all objects to interact with Cheetah streams.
        objects = {}
    end
    
    methods
        function obj = Cheetah(server)
            % Cheetah(server)
            % Create a connection to Cheetah Acquisition System at the given
            % server, which may be either an ip address (e.g. 127.0.0.1 or a
            % fully qualified domain name).
            
            obj.server = server;
            obj.className = mfilename('class');
            if obj.connect(server)
                 if obj.greet()
                     if ~obj.openStreams()
                         error('Failed to create a stream.');
                     end
                 else
                     error('Failed to connect to %s.', server);
                 end
            else
                error('Failed to connect to %s.', server);
            end
        end
        
        function delete(obj)
            % Cheetah.delete()
            % Disconnect from previously established connection.
            
            % Release individual streams.
            for i = 1:numel(obj.objects)
                delete(obj.objects{i});
            end
            obj.disconnect();
        end
        
        function objects = getObjects(obj)
            % objects = Cheetah.getObjects()
            % Return a cell array of objects that interact with acquisition
            % entities loaded in Cheetah.
            
            objects = obj.objects;
        end
    end
    
    methods (Access = private)
        function success = connect(obj, server)
            % success = Cheetah.connect(server)
            % Connect to network server (e.g. 'localhost', '192.168.1.100', ...)
            
            if ~libisloaded('MatlabNetComClient')
                loadlibrary('MatlabNetComClient3_x64', 'MatlabNetComClient3_x64_proto', 'alias', 'MatlabNetComClient');
            end
            if obj.connected
                obj.disconnect();
            end
            if calllib('MatlabNetComClient', 'ConnectToServer', server)
                success = true;
                obj.connected = true;
            else
                success = false;
            end
        end
        
        function success = disconnect(obj)
            % success = Cheetah.disconnect()
            % Disconnect from a previously stablished connection to Cheetah.
            
            if obj.connected && libisloaded('MatlabNetComClient')
                success = calllib('MatlabNetComClient', 'DisconnectFromServer');
                unloadlibrary('MatlabNetComClient');
            else
                success = true;
            end
        end
        
        function success = openStreams(obj)
            % success = Cheetah.openStreams()
            % Read all acquisition entitiets loaded in Cheetah 
            
            if obj.connected
                maxObjects = 5000;
                maxStringLength = 100;
                placeholder = blanks(maxStringLength);
                stringArray = repmat({placeholder}, 1, maxObjects);
                objectPointers = libpointer('stringPtrPtr', stringArray);
                typePointers = libpointer('stringPtrPtr', stringArray);
                [success, names, types, ~, nObjects] = calllib('MatlabNetComClient', 'GetDASObjectsAndTypes', objectPointers, typePointers, maxStringLength, maxObjects);
                names = names(1:nObjects);
                types = types(1:nObjects);
                if success
                    obj.objects = cell(nObjects, 1);
                    for i = 1:nObjects
                        type = types{i};
                        name = names{i};
                        switch type
                            case 'SEScAcqEnt'   % Single electrode.
                                obj.objects{i} = Cheetah.SingleElectrode(name);
                            case 'STScAcqEnt'   % Stereotrode.
                                obj.objects{i} = Cheetah.Stereotrode(name);
                            case 'TTScAcqEnt'   % Tetrode.
                                obj.objects{i} = Cheetah.Tetrode(name);
                            case 'CscAcqEnt'    % Continuously sampled channel.
                                obj.objects{i} = Cheetah.ContinuoslySampled(name);
                            case 'EventAcqEnt'  % Event.
                                obj.objects{i} = Cheetah.Event(name);
                            case 'VTAcqEnt'     % Video tracker.
                                obj.objects{i} = Cheetah.VideoTracker(name);
                            case 'AcqSource'    % Acquisition Source.
                                % not implemented.
                        end
                    end
                    obj.objects(ismember(types, 'AcqSource')) = [];
                end
            else
                success = false;
            end
        end
        
        function success = greet(obj)
            % success = Cheetah.greet()
            % Set application name and post an event to Cheetah.
            
            % This greeting operation may fail despite the fact of the libraries
            % reporting a connection, hence it's a good way of telling if
            % anything will fail.
            if obj.connected
                success = obj.send(sprintf('-PostEvent "%s is connected." 0 0', obj.className));
                success = success && calllib('MatlabNetComClient', 'SetApplicationName', obj.className);
            else
                success = false;
            end
        end
        
        function [success, response] = send(obj, command)
            % [success, response] = Cheetah.send(command)
            % Send a command to Cheetah. Cheetah's documentation lists all
            % valid commands.
            
            if obj.connected
                maxResponseLength = 1000;
                placeholder = blanks(maxResponseLength);
                replyPointer = libpointer('stringPtrPtr', {placeholder});
                [success, ~, response, ~] = calllib('MatlabNetComClient', 'SendCommand', command, replyPointer, maxResponseLength);
            else
                success = false;
                response = '';
            end
        end
    end
end