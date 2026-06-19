function R = observer_position(H, theta_deg, phi_deg)
%OBSERVER_POSITION Geocentric position of a tracking site (Curtis Eq. 5.56).
%
%   R = observer_position(H, theta_deg, phi_deg)
%
%   H           - altitude above the ellipsoid (km)
%   theta_deg   - local sidereal time (degrees)
%   phi_deg     - geodetic latitude (degrees, north positive)
%
%   Returns R = [X; Y; Z] in km (geocentric equatorial frame).

Re = 6378;          % km
f = 0.003353;

phi = deg2rad(phi_deg);
theta = deg2rad(theta_deg);

den = sqrt(1 - (2*f + f^2) * sin(phi)^2);
Rc = Re / den + H;
Rs = Re * (1 - f)^2 / den + H;

R = [Rc * cos(phi) * cos(theta);
     Rc * cos(phi) * sin(theta);
     Rs * sin(phi)];

end
