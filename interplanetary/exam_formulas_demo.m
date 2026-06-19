function exam_formulas_demo()
%EXAM_FORMULAS_DEMO  Numeric checks for common written-exam questions.
%
%   Runs MA016, MA018, MA019, MA020, AOM017, AOM028 style calculations.

clear; clc;

fprintf('=== Written exam formula checks ===\n\n');

% MA019: C3 = v_inf^2
v_inf = 4;
fprintf('MA019: v_inf = %.1f km/s  =>  C3 = %.1f km^2/s^2\n', v_inf, v_inf^2);

% AOM025: escape energy = v_inf^2/2
v_inf = 3;
fprintf('AOM025: v_inf = %.1f km/s  =>  epsilon = v_inf^2/2 = %.1f km^2/s^2\n', v_inf, v_inf^2/2);

% MA016: escape from circular
mu_earth = 398600.4418;
r = 7000;
[v_park, v_esc, dv] = deal(sqrt(mu_earth/r), sqrt(2*mu_earth/r), NaN);
dv = v_esc - v_park;
fprintf('MA016: r = %d km  =>  dv/v_circ = %.3f (expect ~0.414)\n', r, dv/v_park);

% MA018: plane change
v = 10; di = 60;
dv_pc = plane_change_delta_v(v, di);
fprintf('MA018: v = %d km/s, delta_i = %d deg  =>  dv = %.1f km/s\n', v, di, dv_pc);

% MA020: Earth rotation
v_eq = 0.465;
lat = 30;
fprintf('MA020: lat = %d deg  =>  v = %.4f km/s (cos factor = %.3f)\n', ...
    lat, v_eq*cosd(lat), cosd(lat));

% OM028 / MA022: circular orbit v vs r
fprintf('OM028: r doubles  =>  v ratio = 1/sqrt(2) = %.4f\n', 1/sqrt(2));

% AOM017: z = z0 cos(2pi t/T), half orbit
z0 = 50;
fprintf('AOM017: z(T/2) = %.0f m\n', z0 * cos(pi));

% AOM028: delta = 2 asin(1/e), e -> inf
e = 1e6;
delta = rad2deg(2*asin(1/e));
fprintf('AOM028: e = 1e6  =>  delta = %.4f deg\n', delta);

% OM019: Kepler III — a doubles
fprintf('OM019: a doubles  =>  T ratio = 2^(3/2) = %.4f\n', 2^(3/2));

fprintf('\nDone.\n');

end
