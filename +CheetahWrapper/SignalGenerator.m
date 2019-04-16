% SignalGenerator - Create test data.
% SignalGenerator methods:
%   getData - return struct with data fields.

% 2019-02-05. Leonardo Molina.
% 2019-04-10. Last modified.
classdef SignalGenerator < CheetahWrapper.Stream & CheetahWrapper.WaveformTemplate
    properties (Access = private)
        start
        next
        ids
        count
        interval
    end
    
    methods
        function obj = SignalGenerator(name, cheetah, ids, count, interval)
            obj = obj@CheetahWrapper.Stream(name, cheetah);
            obj = obj@CheetahWrapper.WaveformTemplate(name, cheetah);
            
            obj.ids = ids;
            obj.count = count;
            obj.interval = interval;
            obj.next = interval;
            obj.start = tic;
        end
        
        function [spikes, dropped] = getData(obj)
            % SignalGenerator.getData()
            
            nChannels = 4;
            nPoints = 32;
            time = toc(obj.start);
            waveAmplitude = rand() + 1;
            wave = waveAmplitude * sin(linspace(0, 2 * pi, nPoints));
            ttWaves = repmat(wave', 1, nChannels)';
            ttWaves = ttWaves + cumsum(0.1 * ones(size(ttWaves)), 1);
            if time >= obj.next
                obj.next = time + obj.interval;
                nIds = numel(obj.ids);
                nUse = randi([obj.count, nIds]);
                ttWaves = 2 * repmat(ttWaves, 1, 1, nUse);
                d = obj.ids(randperm(nIds));
                id = permute(d(1:nUse), [4, 3, 2, 1]);
            else
                id = 0;
            end
            spikes = squeeze(struct('waveform', num2cell(ttWaves, [1, 2]), 'id', num2cell(id)));
            dropped = 0;
        end
        
        function match = send(varargin)
            match = true;
        end
    end
end