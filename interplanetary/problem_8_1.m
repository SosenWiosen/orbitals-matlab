function problem_8_1()
% prob 8.1 — Hohmann dV earth to saturn, book ans 15.74 km/s

setup();
c = constants_curtis();
h = hohmann_interplanetary(c.earth.R_orbit, c.saturn.R_orbit, c.mu_sun, c.earth.T, c.saturn.T);

fprintf('\nprob 8.1  earth -> saturn Hohmann\n');
fprintf('dv dep = %.4f km/s\n', h.dv_dep);
fprintf('dv arr = %.4f km/s\n', h.dv_arr);
fprintf('total  = %.4f km/s  (book: 15.74)\n', h.dv_total_helio);
fprintf('TOF    = %.0f d\n\n', h.TOF_days);

end
