function [r, v, aux] = state_vector_from_tracking(H, theta_deg, phi_deg, ...
    A_deg, a_deg, rho, rho_dot, A_dot, a_dot)
%STATE_VECTOR_FROM_TRACKING Geocentric state from tracking data (Algorithm 5.4).
%
%   [r, v] = state_vector_from_tracking(H, theta_deg, phi_deg, A_deg, a_deg, ...
%                                       rho, rho_dot, A_dot, a_dot)
%
%   Tracking inputs:
%     H, theta_deg, phi_deg  - site altitude (km), LST (deg), latitude (deg)
%     A_deg, a_deg           - azimuth (deg, clockwise from north) and elevation (deg)
%     rho, rho_dot           - slant range (km) and range rate (km/s)
%     A_dot, a_dot           - azimuth and elevation rates (rad/s)
%
%   Outputs r and v are 3x1 vectors in the geocentric equatorial frame (km, km/s).
%   Optional struct aux returns intermediate quantities from Algorithm 5.4.

omegaE = 72.92e-6;  % rad/s (Eq. 2.67)

% Step 1: observer position (Eq. 5.56)
R = observer_position(H, theta_deg, phi_deg);

% Steps 2-4: line-of-sight unit vector via topocentric horizon frame (Eqs. 5.58, 5.62b, 5.71)
theta = deg2rad(theta_deg);
phi = deg2rad(phi_deg);
A = deg2rad(A_deg);
a = deg2rad(a_deg);

Q_xX = [-sin(theta), -sin(phi)*cos(theta),  cos(phi)*cos(theta);
         cos(theta), -sin(phi)*sin(theta),  cos(phi)*sin(theta);
                0,            cos(phi),              sin(phi)];

l_horizon = [sin(A)*cos(a);
             cos(A)*cos(a);
                    sin(a)];

rho_hat = Q_xX * l_horizon;

% Steps 2-3 (alpha, delta) for reference — Eqs. (5.83a)-(5.83c)
delta = asin(cos(phi)*cos(A)*cos(a) + sin(phi)*sin(a));
cos_delta = cos(delta);
h_arg = (cos(phi)*sin(a) - sin(phi)*cos(A)*cos(a)) / cos_delta;
h_arg = max(-1, min(1, h_arg));

if A_deg > 0 && A_deg < 180
    h = 360 - rad2deg(acos(h_arg));
else
    h = rad2deg(acos(h_arg));
end

alpha = theta_deg - h;
alpha = mod(alpha, 360);

% Step 5: geocentric position (Eq. 5.63)
r = R + rho * rho_hat;

% Step 6: inertial velocity of the site (Eq. 5.66)
R_dot = cross([0; 0; omegaE], R);

% Steps 7-9: time derivative of the line-of-sight unit vector.
% Horizon-frame rates from Eq. (5.58), transformed with Eq. (5.62b) and dQ/dt = omegaE * dQ/dtheta.
dl = [ cos(A)*cos(a)*A_dot - sin(A)*sin(a)*a_dot;
      -sin(A)*cos(a)*A_dot - cos(A)*sin(a)*a_dot;
                         cos(a)*a_dot];

dQ_dtheta = [-cos(theta),  sin(phi)*sin(theta), -cos(phi)*sin(theta);
             -sin(theta), -sin(phi)*cos(theta),  cos(phi)*cos(theta);
                      0,                     0,                     0];

dQdt = omegaE * dQ_dtheta;
rho_hat_dot = dQdt * l_horizon + Q_xX * dl;

% Step 10: geocentric velocity (Eq. 5.64)
v = R_dot + rho_dot * rho_hat + rho * rho_hat_dot;

if nargout > 2
    aux.R = R;
    aux.rho_hat = rho_hat;
    aux.rho_hat_dot = rho_hat_dot;
    aux.delta_deg = rad2deg(delta);
    aux.alpha_deg = alpha;
    aux.h_deg = h;
end

end
