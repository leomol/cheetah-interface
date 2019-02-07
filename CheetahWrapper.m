% CheetahWrapper - Interface with Cheetah Acquisition System for realtime requests.
% A connection starts when the object is created and terminates when the
% object is deleted.
% 
% CheetahWrapper methods:
% getStreams()    - Return a cell array of streams.
% getStream(name) - Return acquisition entity with matching name.
% send(command)   - Send a command to Cheetah.
% 
% CheetahWrapper properties:
% connected       - Whether a connection was established.

% 2011-12-14. Leonardo Molina.
% 2019-02-05. Last modified.
classdef CheetahWrapper < handle
    properties (Dependent)
        connected
    end
    
    properties (Access = private)
        % className - This class' name.
        className
        
        % server - The ip address or domain name of the computer hosting Cheetah.
        server
        
        % connected - Whether a connection has been stablished.
        mConnected = false
        
        % streams - List of all streams to interact with Cheetah streams.
        streams = {}
        
        % names - List of all acquisition entity names.
        names = {}
    end
    
    methods
        function obj = CheetahWrapper(server)
            % CheetahWrapper()
            % CheetahWrapper(server)
            % Create a connection to Cheetah Acquisition System at the given
            % server, which may be either an ip address (e.g. 127.0.0.1 or a
            % fully qualified domain name).
            
            if nargin == 0
                server = 'localhost';
            end
            
            obj.server = server;
            obj.className = mfilename('class');
            if obj.connect(server)
                 if obj.checkin()
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
            % CheetahWrapper.delete()
            % Disconnect from previously established connection.
            
            % Release individual streams.
            for i = 1:numel(obj.streams)
                delete(obj.streams{i});
            end
            obj.disconnect();
        end
        
        function streams = getStreams(obj)
            % streams = CheetahWrapper.getStreams()
            % Return a cell array of streams that interact with acquisition
            % entities loaded in Cheetah.
            
            streams = obj.streams;
        end
        
        function stream = getStream(obj, name)
            % stream = CheetahWrapper.getStream(name);
            % Return acquisition entity with matching name. Return error
            % otherwise.
            
            
            k = ismember(obj.names, name);
            if any(k)
                stream = obj.streams{k};
            else
                error('Stream %s does not exist.', name);
            end
        end
        
        function [success, response] = send(obj, command)
            % [success, response] = CheetahWrapper.send(command)
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
        
        function connected = get.connected(obj)
            connected = obj.mConnected;
        end
    end
    
    methods (Access = private)
        function success = connect(obj, server)
            % success = CheetahWrapper.connect(server)
            % Connect to network server (e.g. 'localhost', '192.168.1.100', ...)
            
            if ~libisloaded('MatlabNetComClient')
                loadlibrary('MatlabNetComClient3_x64', 'MatlabNetComClient3_x64_proto', 'alias', 'MatlabNetComClient');
            end
            if obj.connected
                obj.disconnect();
            end
            if calllib('MatlabNetComClient', 'ConnectToServer', server)
                success = true;
                obj.mConnected = true;
            else
                success = false;
                obj.mConnected = false;
            end
        end
        
        function success = disconnect(obj)
            % success = CheetahWrapper.disconnect()
            % Disconnect from a previously stablished connection to Cheetah.
            
            if obj.connected && libisloaded('MatlabNetComClient')
                success = obj.send(sprintf('-PostEvent "%s disconnected." 0 0', obj.className));
                success = success & calllib('MatlabNetComClient', 'DisconnectFromServer');
                unloadlibrary('MatlabNetComClient');
            else
                success = true;
            end
        end
        
        function success = openStreams(obj)
            % success = CheetahWrapper.openStreams()
            % Read all acquisition entitiets loaded in Cheetah 
            
            if obj.connected
                maxStreams = 5000;
                maxStringLength = 100;
                placeholder = blanks(maxStringLength);
                stringArray = repmat({placeholder}, 1, maxStreams);
                objectPointers = libpointer('stringPtrPtr', stringArray);
                typePointers = libpointer('stringPtrPtr', stringArray);
                [success, tags, types, ~, nStreams] = calllib('MatlabNetComClient', 'GetDASObjectsAndTypes', objectPointers, typePointers, maxStringLength, maxStreams);
                tags = tags(1:nStreams);
                types = types(1:nStreams);
                if success
                    obj.streams = cell(nStreams, 1);
                    for i = 1:nStreams
                        type = types{i};
                        name = tags{i};
                        switch type
                            case 'SEScAcqEnt'   % Single electrode.
                                obj.streams{i} = CheetahWrapper.SingleElectrode(name, obj);
                            case 'STScAcqEnt'   % Stereotrode.
                                obj.streams{i} = CheetahWrapper.Stereotrode(name, obj);
                            case 'TTScAcqEnt'   % Tetrode.
                                obj.streams{i} = CheetahWrapper.Tetrode(name, obj);
                            case 'CscAcqEnt'    % Continuously sampled channel.
                                obj.streams{i} = CheetahWrapper.ContinuoslySampled(name, obj);
                            case 'EventAcqEnt'  % Event.
                                obj.streams{i} = CheetahWrapper.Event(name, obj);
                            case 'VTAcqEnt'     % Video tracker.
                                obj.streams{i} = CheetahWrapper.VideoTracker(name, obj);
                            case 'AcqSource'    % Acquisition Source.
                                % not implemented.
                        end
                    end
                    obj.streams(ismember(types, 'AcqSource')) = [];
                    obj.names = cellfun(@(stream) stream.name, obj.streams, 'UniformOutput', false);
                end
            else
                success = false;
            end
        end
        
        function success = checkin(obj)
            % success = CheetahWrapper.checkin()
            % Set application name and post an event to Cheetah.
            
            % This checkining operation might fail even if libraries report
            % a connection, hence it's a good way of telling if anything
            % will fail.
            if obj.connected
                success = obj.send(sprintf('-PostEvent "%s connected." 0 0', obj.className));
                success = success && calllib('MatlabNetComClient', 'SetApplicationName', obj.className);
            else
                success = false;
            end
        end
    end
end