function plotTetrodeStream()
    error('Untested script.');
    
    % Figure for plotting and releasing resources.
    window = figure('Name', 'Cheetah Interface - Plot tetrode', 'NumberTitle', 'off', 'CloseRequestFcn', @release);
    text = uicontrol('Style', 'Text', 'Units', 'Normalized', 'Position', [0, 0, 1, 0.1], 'String', 'Close to disconnect');
    try
        obj = Cheetah('localhost');
        success = true;
    catch err
        text.String = err.message;
        success = false;
    end
    
    if success
        objects = obj.getObjects;
        classes = cellfun(@class, objects, 'UniformOutput', false);
        % Get the first occurrence of a tetrode.
        k = find(ismember(classes, 'Cheetah.Tetrode'), 1);
        if ~isempty(k)
            numSubChannels = 4;
            spikeSampleWindowSize = 32;
            tt = objects{k};
            % Create as many axes as channels in a tetrode.
            axs = plot(NaN(spikeSampleWindowSize), NaN(spikeSampleWindowSize), '--');
            % XLims is always 1 to 32.
            xlim([1, spikeSampleWindowSize]);
            x = 1:spikeSampleWindowSize;
            % YLims adjuts with new data.
            yMax = 0;
            % Run until figure is closed.
            while ishandle(window)
                % Ignore all data except spike data.
                m = tt.getData.dataArray;
                % Collapse records dimension.
                m = mean(m, 3);
                for i = 1:numSubChannels
                    % Update plots separately.
                    y = m(:, i);
                    set(axs(i), 'XData', x, 'YData', y);
                end
                maxY = max(m.dataArray(:));
                if maxY > yMax
                    % Update axis limits only when necessary for performance.
                    yMax = maxY;
                    ylim([0, yMax]);
                end
                % Refresh figure at each iteration.
                drawnow;
            end
        end
    end
    
    function release()
        % Disconnect from Cheetah to release resources.
        delete(obj);
    end
end