% Example_5_04.m
% Julian day calculation for Curtis Example 5.4 (May 12, 2004, 14:45:30 UT).
%
% Requires: J0.m (Eq. 5.48), julian_day.m optional wrapper.

clear; clc;

year   = 2004;
month  = 5;
day    = 12;
hour   = 14;
minute = 45;
second = 30;

jd = julian_day(year, month, day, hour, minute, second);

fprintf('\nExample 5.4: Julian day calculation\n\n');
fprintf('Input:\n');
fprintf('  Date: %04d-%02d-%02d\n', year, month, day);
fprintf('  UT:   %02d:%02d:%02d\n\n', hour, minute, second);
fprintf('Julian day number = %11.3f\n', jd);

% Book answer: 2,453,138.115 days
