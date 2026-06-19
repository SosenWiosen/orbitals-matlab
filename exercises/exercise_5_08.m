% exercise_5_08.m
% Problem 5.8: Julian day numbers for several epochs.

clear; clc;

cases = {
    'a', 1914, 8,  14, 5,  30, 0, 2420358.729;
    'b', 1946, 4,  18, 14,  0, 0, 2431929.083;
    'c', 2010, 9,   1,  0,  0, 0, 2455440.500;
    'd', 2007, 10, 16, 12,  0, 0, 2454390.000;
};

fprintf('\nExercise 5.8\n\n');
fprintf('%-4s  %11s  %11s\n', 'Part', 'Computed', 'Book');
fprintf('%s\n', repmat('-', 1, 30));

for k = 1:size(cases, 1)
    label = cases{k, 1};
    y = cases{k, 2};
    m = cases{k, 3};
    d = cases{k, 4};
    h = cases{k, 5};
    mi = cases{k, 6};
    s = cases{k, 7};
    expected = cases{k, 8};

    jd = julian_day(y, m, d, h, mi, s);
    fprintf('(%s)  %11.3f  %11.3f\n', label, jd, expected);
end

% Part (e): set your local noon and convert to UT before calling julian_day.
