% ClosedLoop - Produce a default stimulus when the given neuronal ensemble activates.
% Example:
%   callback = @() tone(2250, 0.1);
%   ClosedLoop('-server', 'localhost', '-callback', callback)

% 2018-08-16. Leonardo Molina.
% 2019-04-10. Last modified.
classdef ClosedLoop < handle
    properties (SetAccess = private)
        ids
        include
        count = 2
        window = 0.2
        waveforms
        times
    end
    
    properties (Access = private)
        handles
        functionHandle
        lastFolder = 'C:\Users\molina\Documents\Projects\Interphaser\development\Matlab\cheetah-wrapper\cheetah-wrapper-git\etc\data' % !!
        cheetah
        server
        electrode
        colors = struct('error', [0.90, 0.70, 0.70], 'success', [0.94, 0.94, 0.94]);
        dxN
        dyN
        unitsPerWindow = 6
        nUnits = Inf
    end
    
    methods
        function obj = ClosedLoop(varargin)
            % ClosedLoop()
            % ClosedLoop(..., '-server', server)
            % ClosedLoop(..., '-callback', functionHandle)
            
            obj.server = getParameter(varargin, '-server', {});
            obj.functionHandle = getParameter(varargin, '-callback', {});
            
            % Interface with Cheetah.
            try
                obj.cheetah = CheetahWrapper(obj.server{:});
            catch e
                errordlg(e.message, 'Closed Loop - Error', 'modal');
                rethrow(e);
            end
            
            obj.handles.fig = figure('Name', 'ClosedLoop - Selection window', 'Units', 'Pixels', 'NumberTitle', 'off', 'ToolBar', 'none', 'MenuBar', 'none');
            position = obj.handles.fig.Position;
            drawnow();
            ui = uicontrol();
            uiDyP = ui.Position(4);
            delete(ui);
            totalDy = 2 * uiDyP + position(3) / obj.unitsPerWindow;
            uiDyN = uiDyP / totalDy;
            obj.dxN = 1 / obj.unitsPerWindow;
            obj.dyN = 1 - 2 * uiDyN;
            obj.handles.fig.Position = [position(1:3), totalDy];
            
            obj.handles.scroll = uicontrol('Parent', obj.handles.fig, 'Units', 'Normalized', 'Style', 'Slider', 'Callback', @(h, ~)obj.onSlider(h));
            obj.handles.scroll.Position = [0, 0, 1, uiDyN];
            obj.handles.panel = uipanel('Parent', obj.handles.fig, 'Units', 'Normalized', 'Position', [0, uiDyN, 1, obj.dyN]);
            obj.handles.unitPanel = -1;
            
            yOffset = uiDyN + obj.dyN;
            
            obj.handles.send = uicontrol('Parent', obj.handles.fig, 'Style', 'PushButton', 'Units', 'Normalized', 'Position', [5 * obj.dxN, yOffset, obj.dxN, uiDyN], 'String', 'Send', 'Callback', @(~, ~)obj.send);
            obj.handles.loadData = uicontrol('Parent', obj.handles.fig, 'Style', 'PushButton', 'Units', 'Normalized', 'Position', [4 * obj.dxN, yOffset, obj.dxN, uiDyN], 'String', 'Load', 'Callback', @(~, ~)obj.loadData);
            
            obj.handles.count = uicontrol('Parent', obj.handles.fig, 'Style', 'Edit', 'Units', 'Normalized', 'Position', [0 * obj.dxN, yOffset, obj.dxN, uiDyN], 'String', sprintf('%d', obj.count), 'Callback', @(h, ~)obj.parse(h));
            uicontrol('Parent', obj.handles.fig, 'Style', 'Text', 'Units', 'Normalized','Position', [1 * obj.dxN, yOffset, obj.dxN, uiDyN], 'String', 'min matches');
            
            obj.handles.window = uicontrol('Parent', obj.handles.fig, 'Style', 'Edit', 'Units', 'Normalized', 'Position', [2 * obj.dxN, yOffset, obj.dxN, uiDyN], 'String', sprintf('%.2f', obj.window), 'Callback', @(h, ~)obj.parse(h));
            uicontrol('Parent', obj.handles.fig, 'Style', 'Text', 'Units', 'Normalized', 'Position', [3 * obj.dxN, yOffset, obj.dxN, uiDyN], 'String', 'window (s)');
            
            obj.loadData();
        end
    end
    
    methods (Access = private)
        function onSlider(obj, h)
            position = obj.handles.panel.Position;
            position(1) = -(h.Value - 1)/ obj.unitsPerWindow;
            obj.handles.panel.Position = position;
        end
        
        function loadData(obj)
            [file, folder, index] = uigetfile({'*.ntt;*.nst;*.nse', 'Neuralynx spiking files (*.ntt, *.nst, *.nse)'}, 'Select a spiking file', obj.lastFolder);
            folder = escape(folder);
            success = index > 0;
            
            if success
                obj.lastFolder = folder;
                
                % Define acquisition entity name, waveform file, and cluster file.
                [~, streamName] = fileparts(file);
                spikeFile = sprintf('%s/%s', folder, file);
                clusterFile = sprintf('%s/%s.clu.1', folder, streamName);

                % Get the electrode stream.
                obj.electrode = obj.cheetah.getStream(streamName);
                
                % Read waveforms.
                [obj.waveforms, waveformLimits, obj.times, timeLimits] = CheetahWrapper.getWaveforms(spikeFile, clusterFile);
                obj.ids = cell2mat(obj.waveforms.keys);
                obj.nUnits = numel(obj.ids);
                
                position = obj.handles.panel.Position;
                set(obj.handles.panel, 'Position', [0, position(2), obj.nUnits * obj.dxN, position(4)]);
                if obj.nUnits > obj.unitsPerWindow
                    n = obj.nUnits - obj.unitsPerWindow + 1;
                    set(obj.handles.scroll, 'Visible', 'on', 'Min', 1, 'Max', n, 'Value', (1 + n) / 2, 'SliderStep', [1 1] ./ (n - 1), 'Value', 1);
                else
                    set(obj.handles.scroll, 'Visible', 'off', 'Value', 1);
                end

                % Selection window.
                ylims = [Inf, -Inf];
                firingRates = zeros(1, obj.nUnits);
                for u = 1:obj.nUnits
                    id = obj.ids(u);
                    wvLimits = waveformLimits(id);
                    ylims(1) = min([ylims(1), wvLimits(1, :)]);
                    ylims(2) = max([ylims(2), wvLimits(2, :)]);
                    firingRate = numel(obj.times(u)) / diff(timeLimits);
                    firingRates(u) = firingRate;
                end
                [~, order] = sort(firingRates, 'descend');
                
                % Remove previous units, if any.
                k = ishandle(obj.handles.unitPanel);
                delete(obj.handles.unitPanel(k));
                
                % Plot units from highest to lowest firing rate.
                obj.include = false(1, obj.nUnits);
                dx = 1 / obj.nUnits;
                for u = order
                    id = obj.ids(u);
                    obj.handles.unitPanel(u) = uipanel('Parent', obj.handles.panel, 'Units', 'Normalized');
                    ax = axes('Parent', obj.handles.unitPanel(u), 'Units', 'Normalized', 'Position', [0, 0, 1, 1], 'XTick', [], 'YTick', [], 'Box', 'on', 'Visible', 'off');
                    hold(ax, 'all');
                    % Faded limits.
                    nPoints = size(waveformLimits(id), 2);
                    faces = 1:2 * nPoints;
                    wvLimits = waveformLimits(id);
                    lower = wvLimits(1, :);
                    upper = wvLimits(2, :);
                    vertices = cat(2, [1:nPoints; lower], [nPoints:-1:1; upper(end:-1:1)])';
                    patch('Parent', ax, 'Faces', faces, 'Vertices', vertices, 'FaceColor', 'r', 'EdgeColor', 'none', 'FaceAlpha', 0.10, 'HandleVisibility', 'off');
                    % Mean.
                    plot(ax, mean(obj.waveforms(id), 3));
                    ylim(ax, ylims);
                    obj.handles.checkbox(u) = uicontrol('Parent', obj.handles.panel, 'Units', 'Normalized', 'Style', 'CheckBox', 'String', sprintf('%02i: %.2fHz', id, firingRates(u)), 'Callback', @(h, ~)obj.update(h, u));
                    position = obj.handles.checkbox(u).Position;
                    set(obj.handles.unitPanel(u), 'Position', [(u - 1) * dx, position(4), dx, 1 - position(4)]);
                    set(obj.handles.checkbox(u), 'Position', [(u - 1) * dx, 0, dx, position(4)]);
                end
                obj.parse(obj.handles.count);
                obj.parse(obj.handles.window);
            else
                message = 'You must select a spiking file!';
                errordlg(message, 'ClosedLoop - Error', 'modal');
            end
        end
        
        function update(obj, h, k)
            obj.include(k) = h.Value == 1;
        end
        
        function success = parse(obj, h)
            switch h
                case obj.handles.count
                    try
                        number = str2double(h.String);
                        success = true;
                    catch
                        number = 0;
                        success = false;
                    end
                    if number < obj.nUnits && success && numel(number) == 1 && number > 0 && number == round(number) && ~isnan(number) && ~isinf(number)
                        obj.count = number;
                        set(h, 'BackgroundColor', obj.colors.success);
                    else
                        set(h, 'BackgroundColor', obj.colors.error);
                        success = false;
                    end
                case obj.handles.window
                    try
                        number = str2double(h.String);
                        success = true;
                    catch
                        number = 0;
                        success = false;
                    end
                    if success && numel(number) == 1 && number > 0 && ~isnan(number) && ~isinf(number)
                        obj.window = number;
                        set(h, 'BackgroundColor', obj.colors.success);
                    else
                        set(h, 'BackgroundColor', obj.colors.error);
                        success = false;
                    end
            end
        end
            
        function send(obj)
            % CheetahWrapper.ClosedLoop()
            if obj.parse(obj.handles.count) && obj.parse(obj.handles.window)
                % Clear previous cluster definitions.
                obj.electrode.clear();

                % Send new cluster definition.
                obj.electrode.send(obj.waveforms);

                % Produce a default stimulus when the given neuronal ensemble activates.
                patternTrigger(obj.electrode, obj.ids(obj.include), obj.count, obj.window, obj.functionHandle{:});
            end
        end
    end
end

function text = escape(text)
    text = strrep(text, '\', '/');
end

function value = getParameter(parameters, target, default)
    k = ismember(parameters(1:2:end), target);
    if any(k)
        value = parameters(2 * find(k, 1));
    else
        value = default;
    end
end