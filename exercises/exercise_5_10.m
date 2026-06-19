% exercise_5_10.m
% Problem 5.10: local sidereal time (degrees) at several sites.

clear; clc;

cases = {
    'a', 2008,  1,  1, 12, dms_to_deg(18,  3, 0, 'E'), 298.6;
    'b', 2007, 12, 21, 10, dms_to_deg(144, 58, 0, 'E'),  24.6;
    'c', 2005,  7,  4, 20, dms_to_deg(118, 15, 0, 'W'), 104.7;
    'd', 2006,  2, 15,  3, dms_to_deg(43,   6, 0, 'W'), 146.9;
    'e', 2006,  3, 21,  8, dms_to_deg(131, 56, 0, 'E'),  70.6;
};

fprintf('\nExercise 5.10\n\n');
fprintf('%-4s  %11s  %11s\n', 'Part', 'Computed', 'Book');
fprintf('%s\n', repmat('-', 1, 30));

for k = 1:size(cases, 1)
    label = cases{k, 1};
    y = cases{k, 2};
    m = cases{k, 3};
    d = cases{k, 4};
    ut = cases{k, 5};
    lon = cases{k, 6};
    expected = cases{k, 7};

    theta = local_sidereal_time(y, m, d, ut, lon);
    fprintf('(%s)  %11.1f  %11.1f\n', label, theta, expected);
end

% Part (f): noon today at your location.
% Example:
% lon = dms_to_deg(...);  % your east longitude
% theta = local_sidereal_time(2026, 6, 6, 12, lon);
