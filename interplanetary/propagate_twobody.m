function [R, V] = propagate_twobody(R0, V0, dt, mu)
%PROPAGATE_TWOBODY  Keplerian state propagation (two-body, impulsive-free coast).
%
%   [R, V] = propagate_twobody(R0, V0, dt, mu)
%
%   R0, V0 — initial position (km) and velocity (km/s), 3x1
%   dt     — elapsed time (s); negative for backward propagation
%   mu     — gravitational parameter (km^3/s^2)

if abs(dt) < 1e-6
    R = R0(:);
    V = V0(:);
    return;
end

y0 = [R0(:); V0(:)];
opts = odeset('RelTol', 1e-11, 'AbsTol', 1e-11);
[~, Y] = ode45(@(t, y) twobody_ode(t, y, mu), [0, dt], y0, opts);
R = Y(end, 1:3).';
V = Y(end, 4:6).';

end

function dy = twobody_ode(~, y, mu)
r = y(1:3);
R = norm(r);
dy = [y(4:6); -mu * r / R^3];
end
