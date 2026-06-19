function example_8_4()
% ex 8.4 — mars transfer from 300 km parking

setup();
c = constants_curtis();
h = hohmann_interplanetary(c.earth.R_orbit, c.mars.R_orbit, c.mu_sun);
rp = c.earth.R + 300;
[dv, ~, vc, ~, beta] = departure_dv(h.v_inf_dep, c.earth.mu, rp);

fprintf('\nex 8.4  earth -> mars\n');
fprintf('v_inf = %.3f  (book 2.943)\n', h.v_inf_dep);
fprintf('dv    = %.3f  (book 3.590)\n', dv);
fprintf('beta  = %.1f deg\n\n', beta);

end
