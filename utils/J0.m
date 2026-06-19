function j0 = J0(year, month, day)
%J0 Julian day number at 0 h UT on a calendar date (Curtis Eq. 5.48).
%
%   j0 = J0(year, month, day)
%
%   year  - 1901 to 2099
%   month - 1 to 12
%   day   - 1 to 31
%
%   fix() truncates toward zero, matching INT() in the textbook.

j0 = 367 * year ...
   - fix((7 * (year + fix((month + 9) / 12))) / 4) ...
   + fix((275 * month) / 9) ...
   + day + 1721013.5;

end
