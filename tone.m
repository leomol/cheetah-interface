function tone(frequency, duration)
    % tone(frequency, duration)
    % Play a tone with the given frequency (Hz) and duration (seconds) in the computer speaker.
    
    fs = min(44100, 18 * frequency * duration);
    t = 0:1/fs:duration;
    y = sin(2 * pi * frequency * t);
    sound(y, fs);
end