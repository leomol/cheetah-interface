% pulse(comId, duration)
% Send a pulse to the RTS pin of the serial port with comId (e.g. COM1) for
% a given duration in seconds and without blocking execution.

% 2019-02-03. Leonardo Molina.
% 2019-02-04. Last modification.
function pulse(comId, duration)
    persistent data;
    
    % Remember previous connection with a structure.
    if ~isstruct(data)
        reset();
    end
    
    % Interrupt previous pulse, if any.
    if isvalid(data.timer)
        stop(data.timer);
        delete(data.timer);
    end
    switchOff(data.serial);
    
    % When the comId changes, close previous connection and open a new one.
    if ~strcmp(data.comId, comId)
        % Close previous connection.
        try
            fclose(data.serial);
        catch
        end
        % Create new connection.
        data.serial = serial(comId);
        try
            fopen(data.serial);
            data.comId = comId;
        catch e
            reset();
            rethrow(e);
        end
    end
    
    % Start a new pulse.
    data.timer = timer('TimerFcn', @(~, ~)switchOff(data.serial), 'StartDelay', duration, 'ExecutionMode', 'singleShot');
    data.serial.RequestToSend = 'on';
    start(data.timer);

    function reset()
        data.comId = 'COMXX';
        data.serial = serial(data.comId);
        data.timer = timer();
    end
end

function switchOff(serial)
    serial.RequestToSend = 'off';
end