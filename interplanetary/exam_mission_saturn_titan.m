function exam_mission_saturn_titan()
%EXAM_MISSION_SATURN_TITAN  2.5 h exam template — Curtis Ch. 8 patched conics.
%
%   Earth (LEO) -> Hohmann/Lambert -> Saturn capture -> Hohmann -> Titan
%   Optional: gravity-assist discussion (Sec. 8.9, Cassini Fig. 8.24)
%
%   setup_curtis
%   exam_mission_saturn_titan

setup();
c = constants_curtis();

fprintf('============================================================\n');
fprintf('  EXAM MISSION: Earth -> Saturn -> Titan (Curtis Ch. 8)\n');
fprintf('============================================================\n');

%% --- 1. Hohmann baseline (Problem 8.1, Sec. 8.2) ---
R_E = c.earth.R_orbit;
R_S = c.saturn.R_orbit;
hoh = hohmann_interplanetary(R_E, R_S, c.mu_sun, c.earth.T, c.saturn.T);

fprintf('\n--- 1. Hohmann baseline (Sec. 8.2) ---\n');
fprintf('Helio dv at Earth SOI:   %.3f km/s\n', hoh.dv_dep);
fprintf('Helio dv at Saturn SOI:  %.3f km/s\n', hoh.dv_arr);
fprintf('Total heliocentric dv:   %.3f km/s  (Prob. 8.1: 15.74)\n', hoh.dv_total_helio);
fprintf('TOF:                     %.0f days (%.1f yr)\n', hoh.TOF_days, hoh.TOF_years);
fprintf('Launch phase angle phi0: %.1f deg\n', hoh.phi0_deg);

T_syn = synodic_period(c.earth.T, c.saturn.T);
fprintf('Synodic period (8.10):   %.0f days\n', T_syn);

%% --- 2. LEO departure (Sec. 8.6, Eq. 8.42) ---
h_park = 200;  % km — change for your scenario
rp = c.earth.R + h_park;
[dv_leo, ~, vc, ~, ~] = departure_dv(hoh.v_inf_dep, c.earth.mu, rp);

fprintf('\n--- 2. Earth departure from %d-km parking (Sec. 8.6) ---\n', h_park);
fprintf('v_inf:                   %.3f km/s\n', hoh.v_inf_dep);
fprintf('C3:                      %.2f km^2/s^2\n', hoh.v_inf_dep^2);
fprintf('v_circ:                  %.3f km/s\n', vc);
fprintf('delta-v (LEO escape):    %.3f km/s\n', dv_leo);

%% --- 3. Saturn capture (Sec. 8.8) ---
h_cap = 50000;  % km altitude above Saturn cloud tops
rp_sat = c.saturn.R + h_cap;
e_cap = 0;  % circular capture
dv_cap = capture_dv(hoh.v_inf_arr, c.saturn.mu, rp_sat, e_cap);

fprintf('\n--- 3. Saturn SOI capture (Sec. 8.8) ---\n');
fprintf('v_inf at Saturn:         %.3f km/s\n', hoh.v_inf_arr);
fprintf('Capture radius:          %.0f km\n', rp_sat);
fprintf('delta-v (capture):       %.3f km/s\n', dv_cap);

%% --- 4. Saturn -> Titan (Ch. 6 Hohmann) ---
r_titan = c.titan.a;
[dv_titan, ~, ~] = hohmann_planet(c.saturn.mu, rp_sat, r_titan);

fprintf('\n--- 4. Saturn parking -> Titan orbit (Ch. 6) ---\n');
fprintf('Titan semi-major axis:   %.0f km\n', r_titan);
fprintf('delta-v (Hohmann):       %.3f km/s\n', dv_titan);

%% --- 5. Total delta-v budget ---
dv_total = dv_leo + dv_cap + dv_titan;

fprintf('\n--- 5. DELTA-V BUDGET (impulsive, patched conics) ---\n');
fprintf('  %-22s %8.3f km/s\n', 'LEO escape', dv_leo);
fprintf('  %-22s %8.3f km/s\n', 'Saturn capture', dv_cap);
fprintf('  %-22s %8.3f km/s\n', 'Saturn -> Titan', dv_titan);
fprintf('  %s\n', repmat('-', 1, 32));
fprintf('  %-22s %8.3f km/s\n', 'TOTAL (main burns)', dv_total);
fprintf('  (Heliocentric SOI burns at Earth/Saturn are kinematic;\n');
fprintf('   launch/arrival burns above include v_inf from Hohmann.)\n');

%% --- 6. SOI (Sec. 8.4) ---
fprintf('\n--- 6. Spheres of influence (Eq. 8.34) ---\n');
fprintf('  Earth:   %.0f km\n', c.earth.r_soi);
fprintf('  Jupiter: %.0f km\n', c.jupiter.r_soi);
fprintf('  Saturn:  %.0f km\n', c.saturn.r_soi);

%% --- 7. Lambert example (Algorithm 8.2, Sec. 8.11) ---
fprintf('\n--- 7. Non-Hohmann leg (Algorithm 8.2) — optional dates ---\n');
fprintf('  Running Earth->Saturn, TOF = Hohmann TOF...\n');
dep = [2026 4 1 0 0 0];
try
    lam = interplanetary_lambert('earth', dep, 'saturn', [], hoh.TOF_days);
    fprintf('  Departure v_inf (Lambert): %.3f km/s  C3 = %.2f\n', ...
        lam.v_inf_dep, lam.v_inf_dep^2);
    fprintf('  Arrival v_inf:             %.3f km/s\n', lam.v_inf_arr);
    [dv_lam, ~, ~] = departure_dv(lam.v_inf_dep, c.earth.mu, rp);
    fprintf('  LEO delta-v for Lambert:   %.3f km/s  (vs Hohmann %.3f)\n', dv_lam, dv_leo);
catch ME
    fprintf('  Lambert solve skipped: %s\n', ME.message);
end

%% --- 8. Gravity assist (Sec. 8.9) — conceptual, not in Hohmann budget ---
fprintf('\n--- 8. Gravity assist (Sec. 8.9) — exam discussion only ---\n');
fprintf('  Direct Hohmann launch C3 is very high for Saturn.\n');
fprintf('  Cassini (Fig. 8.24): Venus x2, Earth, Jupiter flybys lowered launch energy.\n');
rp_jup = c.jupiter.R + 50000;
v_inf_jup = 4.0;  % illustrative approach speed at Jupiter SOI
[delta_j, e_j] = flyby_delta(rp_jup, v_inf_jup, c.jupiter.mu);
fprintf('  Example Jupiter flyby: rp = %.0f km, v_inf = %.1f km/s\n', rp_jup, v_inf_jup);
fprintf('  Turn angle delta (8.54): %.1f deg, e = %.2f\n', delta_j, e_j);
fprintf('  For exam: describe sequence + delta/rp; do not add to budget unless targeted.\n');

%% --- 9. Feasibility checklist ---
fprintf('\n--- 9. FEASIBILITY (write in exam report) ---\n');
fprintf('  [ ] Patched conics valid (rp >> body radius, away from SOI edges)\n');
fprintf('  [ ] Launch window every synodic period (~%.0f days)\n', T_syn);
fprintf('  [ ] Total TOF ~%.1f yr (Hohmann); Cassini ~7 yr with flybys\n', hoh.TOF_years);
fprintf('  [ ] Midcourse corrections likely (Sec. 8.7 sensitivity)\n');
fprintf('  [ ] Conclusion: feasible with GAs / heavy lift for direct Hohmann\n\n');

end
