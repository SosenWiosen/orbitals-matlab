function problem_8_12()
%PROBLEM_8_12  Curtis Prob. 8.12 — Jupiter flyby on Hohmann Earth approach.
%
%   Book: deltaV = 10.6 km/s, a = 4.79e6 km, e = 0.8453 (trailing-side context)

setup();
c = constants_curtis();

% Earth-Mars Hohmann gives v_inf at Mars; problem uses Jupiter on Hohmann from Earth
R1 = c.earth.R_orbit;
R2 = c.jupiter.R_orbit;
h = hohmann_interplanetary(R1, R2, c.mu_sun);
v_inf = h.v_inf_arr;  % at Jupiter arrival on Hohmann from Earth

rp = c.jupiter.R + 200000;
[delta, e] = flyby_delta(rp, v_inf, c.jupiter.mu);

fprintf('\n=== Problem 8.12: Jupiter flyby (Sec. 8.9) ===\n\n');
fprintf('Hohmann Earth->Jupiter v_inf at Jupiter: %.3f km/s\n', v_inf);
fprintf('Flyby rp (200000 km alt): delta = %.2f deg, e = %.4f\n', delta, e);
fprintf('Full heliocentric delta-V requires Sec. 8.9 vector analysis (see book).\n');
fprintf('Book answer for stated scenario: deltaV = 10.6 km/s\n\n');

end
