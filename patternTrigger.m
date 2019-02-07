% patternTrigger(stream)
% Plot spikes from a Cheetah Acquisition Entity (e.g. tetrode, stereotrode, 
% single electrode).
% 
% patternTrigger(stream, ids, count, window, <stimulationFunction>)
% Trigger a stimulation function (e.g. play tone) when a subset of neurons
% activate within a time window.
% 
% Script assumes that cluster definitions or waveform limits have been set
% in the acquisition system.
% 
% Example:
%     streamName = 'TT1';
%     waveformFile = 'TT1.nse';
%     clusterFile = 'TT1.clu.1';
%     ids = 1:10;
%     count = 2;
%     window = 0.200;
%     cheetah = CheetahWrapper();
%     stream = cheetah.getStream(streamName);
%     stream.send(waveformFile, clusterFile);
%     patternTrigger(stream, ids, count, window);
%     
% Alternatively, provide your own stimulation function:
%     stimulationFunction = @() tone(2250, 0.1);
%     patternTrigger(stream, ids count, window, stimulationFunction);

% 2018-08-12. Leonardo Molina.
% 2019-02-07. Last modified.
function patternTrigger(stream, ids, count, window, stimulationFunction)
    % Expect 1 or 4 arguments.
    if nargin == 0 || (nargin > 1 && nargin < 4)
        help(mfilename());
        return
    end
    % Stimulation function defaults to playing a tone.
    if nargin < 5
        stimulationFunction = @() tone(2250, 0.1);
    end
    if nargin == 1
        ids = [];
        count = 0;
        window = 0;
    end
    count = min(count, numel(ids));
    
    % Figure for plotting and releasing resources.
    handle = figure('Name', 'Cheetah Wrapper - Pattern Trigger', 'NumberTitle', 'off');
    % Create a palette to color spikes from different clusters.
    rng(0);
    colors = colorcube(100);
    colors(diff(colors, 2, 2) == 0, :) = [];
    colors = colors(randperm(size(colors, 1)), :);
    % Time at which a neuron was last active.
    activationTime = -Inf * ones(size(ids));
    start = tic;
    % Flash screen after a match.
    rearmTime = 0;
    rearmInterval = 0.25;
    % Streams allowed for this test.
    compatibleStreams = {'CheetahWrapper.Tetrode', 'CheetahWrapper.Stereotrode', 'CheetahWrapper.SingleElectrode', 'SignalGenerator'};
    if any(ismember(compatibleStreams, class(stream)))
        spikeSampleWindowSize = 1;
        % Create as many plot handles as channels in a tetrode.
        channelHandles = plot(NaN(2, 10), NaN(2, 10), '--');
        % YLims adjuts with new data.
        yMax = 0;
        yMin = 0;
        % Run until figure is closed.
        while ishandle(handle)
            time = toc(start);
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
                    set(channelHandles(c), 'XData', x, 'YData', y, 'Color', colors(data(d).id + 1, :));
                    k = ismember(ids, data(d).id);
                    if any(k)
                        activationTime(k) = time;
                    end
                    if time >= rearmTime
                        set(gca, 'Color', [1, 1, 1]);
                        if sum(time - activationTime <= window) >= count
                            rearmTime = time + rearmInterval;
                            set(gca, 'Color', [1, 1, 0]);
                            stimulationFunction();
                        end
                    end
                end
                % Update axis limits only when necessary for performance.
                maxY = max(data(d).waveform(:));
                if maxY > yMax
                    yMax = maxY;
                    ylim([yMin, yMax]);
                end
                minY = min(data(d).waveform(:));
                if minY < yMin
                    yMin = minY;
                    ylim([yMin, yMax]);
                end
            end
            % Refresh figure at each iteration.
            drawnow;
        end
    end
end