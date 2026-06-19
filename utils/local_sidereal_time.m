function theta = local_sidereal_time(year, month, day, ut_hours, east_longitude_deg)
%LOCAL_SIDEREAL_TIME Local sidereal time in degrees (Curtis Algorithm 5.3).
%
%   theta = local_sidereal_time(year, month, day, ut_hours, east_longitude_deg)
%
%   ut_hours            - universal time in decimal hours
%   east_longitude_deg  - east longitude in degrees (west is negative)
%
%   Uses Eqs. 5.48 to 5.52. Result is wrapped to [0, 360).

j0 = J0(year, month, day);

% Eq. (5.49): Julian centuries from J2000
T0 = (j0 - 2451545) / 36525;

% Eq. (5.50): Greenwich sidereal time at 0 h UT
theta_g0 = 100.4606184 ...
         + 36000.77004 * T0 ...
         + 0.000387933 * T0^2 ...
         - 2.583e-8 * T0^3;
theta_g0 = wrap360(theta_g0);

% Eq. (5.51): Greenwich sidereal time at the given UT
theta_g = theta_g0 + 360.98564724 * ut_hours / 24;
theta_g = wrap360(theta_g);

% Eq. (5.52): local sidereal time
theta = wrap360(theta_g + east_longitude_deg);

end
