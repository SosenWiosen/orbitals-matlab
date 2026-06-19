function jd = julian_day(year, month, day, hour, minute, second)
%JULIAN_DAY Julian day number for a UT epoch (Curtis Eqs. 5.47 and 5.48).
%
%   jd = julian_day(year, month, day)
%   jd = julian_day(year, month, day, hour)
%   jd = julian_day(year, month, day, hour, minute, second)
%
%   hour, minute, second default to 0 when omitted.

if nargin < 4, hour = 0; end
if nargin < 5, minute = 0; end
if nargin < 6, second = 0; end

ut = hour + minute / 60 + second / 3600;
j0 = J0(year, month, day);
jd = j0 + ut / 24;

end
