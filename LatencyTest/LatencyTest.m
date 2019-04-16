%% 2019-04-10. Leonardo Molina
 % 2019-05-15. Last modified.

%% Arduino configuration and connection.
portName = 'COM4';          % COM port of the Arduino.
nSync = 100;                % Bytes for synchronization.
baudrate = 115200;          % Serial baudrate.
totalDuration = 2000;       % Duration of the waveform (us).
pulseInterval = 100000;     % Pause between pulses (us).
nEchoTests = 1000;          % Number of pulses to test in Arduino.
nPulseTests = 1000;         % Number of pulses to test in both systems.

device = serial(portName, 'BaudRate', baudrate);
device.Timeout = totalDuration * 1e-6 + 0.1;
fopen(device);

%% Cheetah configuration and connection.
streamName = 'TT1';         % Cheeetah acquisition entity sampling spikes.
spikesSamplingRate = 32000; % Cheetah's sampling rate.
nSamples = 32;              % Cheetah's number of samples on a spike.
cheetah = CheetahWrapper();
stream = cheetah.getStream(streamName);

%% Sync. Make sure PC and Arduino are synchronized.
sync = 0;
while sync < nSync
    input = fread(device, 1, 'uint8');
    if input == 0
        sync = sync + 1;
    else
        sync = 0;
    end
end
fprintf('Synchronized.\n');

%% Time USB/UART delays; test below is more exhaustive.
echoDelays = NaN(nEchoTests, 1);
for pulseId = 1:nEchoTests
    number = uint8(mod(pulseId - 1, 255) + 1);
    fwrite(device, number, 'uint8');
    start = tic;
    while fread(device, 1, 'uint8') ~= number
        fprintf(2, 'Not in sync.\n');
    end
    echoDelays(pulseId) = toc(start);
end
% Remove 2% extreme points.
mn = prctile(echoDelays, 01);
mx = prctile(echoDelays, 99);
arduinoDelays = echoDelays(echoDelays >= mn & echoDelays <= mx) / 2;
fprintf('Delay introduced by the test. av:%dus min:%dus max:%dus std:%dus\n', round(mean(arduinoDelays * 1e6)), round(min(arduinoDelays * 1e6)), round(max(arduinoDelays * 1e6)), round(std(arduinoDelays * 1e6)));

%% Start test.
data = struct('testTime', {}, 'arduinoDelay', {}, 'arduinoTime', {}, 'arduinoWaveform', {}, 'cheetahTime', {}, 'cheetahWaveform', {});
% Start timer.
start = tic;
for pulseId = 1:nPulseTests
    % Request pulse.
    arduinoFullInputs = zeros(0, 1);
    requestStart = tic;
    
    % Clear Cheetah's buffer.
    while numel(stream.getData()) > 0
    end
    
    fwrite(device, 0, 'uint8');
    data(pulseId).testTime = toc(start);
    % Time response from both Cheetah and Arduino.
    arduinoResponded = false;
    cheetahResponded = false;
    acknowledged = false;
    while ~arduinoResponded || ~cheetahResponded
        time = toc(start);
        % Arduino inputs.
        if ~arduinoResponded && device.BytesAvailable > 0
            % Non-blocking read.
            inputs = fread(device, device.BytesAvailable, 'uint8');
            if ~isempty(inputs)
                if ~acknowledged
                    acknowledged = true;
                    data(pulseId).arduinoDelay = toc(requestStart) / 2;
                end
                % Concatenate input data.
                arduinoFullInputs = cat(1, arduinoFullInputs, inputs);
                if numel(arduinoFullInputs) >= 2 && all(arduinoFullInputs(end-1:end) == 0)
                    % Arduino signal end of wave.
                    arduinoResponded = true;
                    data(pulseId).arduinoTime = time;
                    fprintf('Pulse id:%d\n', pulseId);
                end
            end
        end
        
        % Cheetah inputs.
        if ~cheetahResponded
            cheetahData = stream.getData();
            k = [cheetahData.id];
            if numel(k) > 0
                cheetahResponded = true;
                data(pulseId).cheetahTime = time;
            end
        end
    end
    pause(pulseInterval * 1e-6);
end


%% Plots.
name = sprintf('USB/UART communication delays introduced by this test (n = %d).', nEchoTests);
figure('Name', name);
histogram(1e3 * arduinoDelays);
title(name);
xlabel('Delay (ms)');
ylabel('Count')

%%
name = sprintf('Distribution of delays introduced by Cheetah (n = %d).', nPulseTests);
figure('Name', name);
testTime = [data.testTime] - [data.arduinoDelay];
cheetahTime = [data.cheetahTime];
cheetahDelays = cheetahTime - testTime;
% Remove 2% extreme points.
mn = prctile(cheetahDelays, 01);
mx = prctile(cheetahDelays, 99);
cheetahDelays = cheetahDelays(cheetahDelays >= mn & cheetahDelays <= mx) / 2;
histogram(1e3 * cheetahDelays);
title(name);
xlabel('Delay (ms)');
ylabel('Count')