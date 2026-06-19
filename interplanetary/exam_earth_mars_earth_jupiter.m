function exam_earth_mars_earth_jupiter()
% E-M-E-J mission, patched conics
% dates from exam sheet: dep Dec26, Mars Aug27, Earth Dec28, Jup Sep31

setup();
c = constants_curtis();
mu = c.mu_sun;
AU = c.AU;

% --- dates [y m d h min s] ---
t0   = [2026 12 1 0 0 0];
tM   = [2027  8 1 0 0 0];
tE   = [2028 12 1 0 0 0];
tJ   = [2031  9 1 0 0 0];

tof_EM = days_between(t0, tM);
tof_ME = days_between(tM, tE);
tof_EJ = days_between(tE, tJ);

fprintf('\n--- timeline ---\n');
fprintf('Earth dep     %04d-%02d-%02d\n', t0(1:3));
fprintf('Mars flyby    %04d-%02d-%02d   (%.0f d)\n', tM(1:3), tof_EM);
fprintf('Earth flyby   %04d-%02d-%02d   (%.0f d)\n', tE(1:3), tof_ME);
fprintf('Jupiter arr   %04d-%02d-%02d   (%.0f d)\n', tJ(1:3), tof_EJ);
fprintf('total %.0f d = %.2f yr\n', tof_EM+tof_ME+tof_EJ, (tof_EM+tof_ME+tof_EJ)/365.25);

%% leg 1: Earth -> Mars (Lambert, alg 8.2)
leg1 = interplanetary_lambert('earth', t0, 'mars', tM, tof_EM);
[R_E, ~] = planet_elements_and_sv('earth', t0(1), t0(2), t0(3), 0, 0, 0);
[R_M, ~] = planet_elements_and_sv('mars', tM(1), tM(2), tM(3), 0, 0, 0);
phi = heliocentric_phase_angle(R_E, R_M);

nM = 2*pi / (c.mars.T * 86400);
phi_hoh = rad2deg(pi - nM * tof_EM * 86400);   % eq 8.12 ref

fprintf('\n--- 2) Earth-Mars ---\n');
fprintf('TOF = %.1f d\n', tof_EM);
fprintf('phi = %.1f deg  (Hohmann ref %.1f deg)\n', phi, phi_hoh);
fprintf('v_inf Earth = %.3f km/s,  C3 = %.1f\n', leg1.v_inf_dep, leg1.v_inf_dep^2);
fprintf('v_inf Mars  = %.3f km/s\n', leg1.v_inf_arr);

%% 1) escape from 300 km LEO — three perigee burns (ch.6 + eq 8.40)
rp = c.earth.R + 300;
Ra1 = 120000;    % first apogee, km
Ra2 = 800000;    % second apogee
[dv_leo, dv123] = multiburn_leo_escape(leg1.v_inf_dep, c.earth.mu, rp, Ra1, Ra2);

fprintf('\n--- 1) Earth escape ---\n');
fprintf('need v_inf = %.3f km/s from leg 1\n', leg1.v_inf_dep);
fprintf('burn 1 (perigee, Ra=%.0f km):  dv = %.4f km/s\n', Ra1, dv123(1));
fprintf('burn 2 (perigee, Ra=%.0f km):  dv = %.4f km/s\n', Ra2, dv123(2));
fprintf('burn 3 (perigee, escape):        dv = %.4f km/s\n', dv123(3));
fprintf('sum = %.4f km/s\n', dv_leo);

%% 3) Mars GA
rpM = c.mars.R + 500;
fbM = flyby_patch(leg1.V2_planet, leg1.V_arr, rpM, c.mars.mu, true);

fprintf('\n--- 3) Mars flyby ---\n');
fprintf('rp = %.0f km (h = %.0f km)\n', rpM, rpM-c.mars.R);
fprintf('v_inf = %.3f km/s\n', fbM.v_inf);
fprintf('delta = %.2f deg,  e = %.2f  (eq 8.54)\n', fbM.delta_deg, fbM.e);
fprintf('dV_sun = %.3f km/s\n', fbM.dV_sun);

%% 4) Mars -> Earth
leg2 = interplanetary_lambert('mars', tM, 'earth', tE, tof_ME);
[R_M2, ~] = planet_elements_and_sv('mars', tM(1), tM(2), tM(3), 0, 0, 0);
[R_E2, ~] = planet_elements_and_sv('earth', tE(1), tE(2), tE(3), 0, 0, 0);
phi2 = heliocentric_phase_angle(R_M2, R_E2);

fprintf('\n--- 4) Mars-Earth ---\n');
fprintf('TOF = %.1f d,  phi = %.1f deg\n', tof_ME, phi2);
fprintf('v_inf Mars  = %.3f km/s\n', leg2.v_inf_dep);
fprintf('v_inf Earth = %.3f km/s\n', leg2.v_inf_arr);

%% 5) Earth GA  (trailing side -> speed up toward Jupiter, like Cassini)
rpE = c.earth.R + 1000;
fbE = flyby_patch(leg2.V2_planet, leg2.V_arr, rpE, c.earth.mu, false);

fprintf('\n--- 5) Earth flyby ---\n');
fprintf('rp = %.0f km\n', rpE);
fprintf('delta = %.2f deg\n', fbE.delta_deg);
fprintf('dV_sun = %.3f km/s\n', fbE.dV_sun);

%% 6) Earth -> Jupiter
leg3 = interplanetary_lambert('earth', tE, 'jupiter', tJ, tof_EJ);
[R_E3, ~] = planet_elements_and_sv('earth', tE(1), tE(2), tE(3), 0, 0, 0);
[R_J, ~]  = planet_elements_and_sv('jupiter', tJ(1), tJ(2), tJ(3), 0, 0, 0);
phi3 = heliocentric_phase_angle(R_E3, R_J);

rpJ = c.jupiter.R + 100000;
dv_cap = capture_dv(leg3.v_inf_arr, c.jupiter.mu, rpJ, 0);

fprintf('\n--- 6) Earth-Jupiter ---\n');
fprintf('TOF = %.1f d (%.2f yr)\n', tof_EJ, tof_EJ/365.25);
fprintf('phi = %.1f deg\n', phi3);
fprintf('v_inf dep = %.3f km/s,  arr = %.3f km/s\n', leg3.v_inf_dep, leg3.v_inf_arr);
fprintf('Jupiter capture dv ~ %.3f km/s (rp = %.0f km)\n', dv_cap, rpJ);

%% 7) asteroid belt on E-J leg
belt = asteroid_belt_crossing(leg3.R1, leg3.V_dep, leg3.R2, leg3.V_arr, mu, AU);

fprintf('\n--- 7) asteroid belt ---\n');
fprintf('E-J orbit: rp = %.2f AU, ra = %.2f AU\n', belt.rp_AU, belt.ra_AU);
if belt.crosses
    fprintf('crosses 2.1-3.3 AU band — yes\n');
else
    fprintf('crosses 2.1-3.3 AU band — no\n');
end
fprintf('mitigation: bump i a few deg off ecliptic, Whipple shield, TCM if needed\n');

%% dv table
dv_tcm = 0.05;
fprintf('\n--- dv budget ---\n');
fprintf('LEO escape (3 burns):  %.4f\n', dv_leo);
fprintf('TCM reserve:           %.4f\n', dv_tcm);
fprintf('Jupiter capture:       %.4f\n', dv_cap);
fprintf('TOTAL propulsive:      %.4f km/s\n', dv_leo + dv_tcm + dv_cap);
fprintf('GA (no fuel): Mars %.3f, Earth %.3f km/s heliocentric\n', fbM.dV_sun, fbE.dV_sun);

fprintf('\n');

end
