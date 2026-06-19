function plot_launch_window(planet1, planet2)
%PLOT_LAUNCH_WINDOW  Optional: C3 porkchop (Curtis Sec. 8.11). Slow scan.
%
%   plot_launch_window('earth', 'jupiter')

setup();
c = constants_curtis();
T_syn = synodic_period(c.(planet1).T, c.(planet2).T);
hoh = hohmann_interplanetary(c.(planet1).R_orbit, c.(planet2).R_orbit, c.mu_sun);

tof_vec = linspace(0.7*hoh.TOF_days, 1.4*hoh.TOF_days, 15);
dep0 = [2026 1 1 0 0 0];
n_dep = 15;
dep_days = linspace(0, T_syn, n_dep);
C3 = nan(numel(tof_vec), n_dep);

fprintf('Scanning launch window...\n');
for j = 1:n_dep
    jd = julian_day(dep0(1), dep0(2), dep0(3), dep0(4), dep0(5), dep0(6)) + dep_days(j);
    dep = jd_to_epoch(jd);
    for i = 1:numel(tof_vec)
        try
            o = interplanetary_lambert(planet1, dep, planet2, [], tof_vec(i));
            C3(i,j) = o.v_inf_dep^2;
        catch
        end
    end
end

figure('Name', sprintf('C3: %s to %s', planet1, planet2), 'Color', 'w');
contourf(dep_days, tof_vec, C3, 12, 'LineColor', 'none');
colorbar;
xlabel('Departure offset (days)'); ylabel('TOF (days)');
title(sprintf('C_3 (km^2/s^2): %s \\rightarrow %s', planet1, planet2));

end

function ep = jd_to_epoch(jd)
j = jd + 0.5; Z = floor(j); F = j - Z;
if Z < 2299161, A = Z; else
    a = floor((Z - 1867216.25) / 36524.25);
    A = Z + 1 + a - floor(a/4);
end
B = A + 1524; C = floor((B - 122.1) / 365.25);
y = floor(365.25 * C); D = floor((B - y) / 30.6001);
d = B - y - floor(30.6001 * D); m = D - 1;
if m > 12, m = m - 12; end
y = C - 4716; if m > 2, y = y - 1; end
ut = F * 24;
ep = [y, m, d, floor(ut), floor((ut-floor(ut))*60), 0];
end
