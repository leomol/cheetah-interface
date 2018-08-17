% spikeTrigger(streamName)
% Plot spikes from a Cheetah Acquisition Entity (e.g. tetrode, stereotrode, 
% single electrode).
% 
% spikeTrigger(streamName, id)
% Beep when a spike matches the given id number. Spikes may only have an id
% if a cluster definition or waveform limits have been set in the acquisition
% system.
% 
% Example:
%   cheetah = CheetahWrapper();
%   stream = cheetah.getStream('TT48');
%   stream.send('TT48.nse', 'TT48.clu.1');
%   triggerId = 2;
%   spikeTrigger(stream, triggerId);

% 2018-08-12. Leonardo Molina.
% 2018-08-16. Last modified.
function spikeTrigger(stream, triggerIds)
    % Figure for plotting and releasing resources.
    window = figure('Name', 'Cheetah Wrapper - Plot spikes', 'NumberTitle', 'off');
    % Create a palette to color spikes from different clusters.
    rng(0);
    colors = colorcube(100);
    colors = colors(randperm(size(colors, 1)), :);
    % Streams allowed for this test.
    compatibleStreams = {'CheetahWrapper.Tetrode', 'CheetahWrapper.Stereotrode', 'CheetahWrapper.SingleElectrode'};
    if any(ismember(compatibleStreams, class(stream)))
        spikeSampleWindowSize = 1;
        % Create as many axes as channels in a tetrode.
        axs = plot(NaN(2, 2), NaN(2, 2), '--');
        % YLims adjuts with new data.
        yMax = 0;
        yMin = 0;
        % Run until figure is closed.
        while ishandle(window)
            % Ignore all data except spike data.
            data = stream.getData();
            for d = 1:numel(data)
                for c = 1:size(data(d).waveform, 1)
                    % Plot each channel separately.
                    y = data(d).waveform(c, :);
                    x = 1:numel(y);
                    if spikeSampleWindowSize < numel(x)
                        spikeSampleWindowSize = numel(x);
                        xlim([1, spikeSampleWindowSize]);
                    end
                    % Increase the palette to include id.
                    id = data(d).id + 1;
                    while id > size(colors, 1)
                        colors = repmat(colors, 2, 1);
                    end
                    
                    set(axs(c), 'XData', x, 'YData', y, 'Color', colors(data(d).id + 1, :));
                    if any(ismember(triggerIds, data(d).id))
                        set(axs(c), 'LineWidth', 5);
                        tone(2250, 0.1);
                        % Refresh figure at each iteration.
                        drawnow;
                        pause(0.050);
                    else
                        set(axs(c), 'LineWidth', 1);
                        drawnow;
                    end
                end
                maxY = max(data(d).waveform(:));
                if maxY > yMax
                    % Update axis limits only when necessary for performance.
                    yMax = maxY;
                    ylim([yMin, yMax]);
                end
                minY = min(data(d).waveform(:));
                if minY < yMin
                    % Update axis limits only when necessary for performance.
                    yMin = minY;
                    ylim([yMin, yMax]);
                end
            end
        end
    end
end
        
function tone(frequency, duration)
    % tone(frequency, duration)
    % Play a tone with the given frequency (Hz) and duration (seconds) in the computer speaker.

    fs = min(44100, 18 * frequency * duration);
    t = 0:1/fs:duration;
    y = sin(2 * pi * frequency * t);
    sound(y, fs);
end