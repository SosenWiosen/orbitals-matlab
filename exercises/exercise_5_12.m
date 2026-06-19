% exercise_5_12.m
% Problem 5.12: state vector from tracking data (Algorithm 5.4).

clear; clc;

H = 0;              % km, sea level
theta = 40;         % deg, local sidereal time
phi = 35;           % deg, latitude

A = 36.0;           % deg, azimuth
a = 36.6;           % deg, elevation
rho = 988;          % km
rho_dot = 4.86;     % km/s

A_dot = deg2rad(0.590);    % rad/s
a_dot = -deg2rad(0.263);   % rad/s (elevation decreasing)

[r, v, aux] = state_vector_from_tracking(H, theta, phi, A, a, rho, rho_dot, A_dot, a_dot);

fprintf('\nExercise 5.12\n\n');
fprintf('Observer R = [%.1f, %.1f, %.1f] km\n', aux.R);
fprintf('alpha = %.2f deg, delta = %.2f deg\n', aux.alpha_deg, aux.delta_deg);
fprintf('\nr = [%.1f, %.1f, %.1f] km\n', r);
fprintf('|r| = %.1f km  (book: 7003.3 km)\n\n', norm(r));
fprintf('v = [%.3f, %.3f, %.3f] km/s\n', v);
fprintf('|v| = %.3f km/s  (book: 10.922 km/s)\n', norm(v));
