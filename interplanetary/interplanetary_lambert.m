function out = interplanetary_lambert(planet1, dep, planet2, arr, tof_days)
%INTERPLANETARY_LAMBERT  Curtis Algorithm 8.2 (interplanetary.m).
%
%   out = interplanetary_lambert('earth', dep, 'saturn', arr, tof_days)
%
%   dep, arr — [year month day hour minute second] UTC
%   tof_days — time of flight (days)
%
%   Example (Mars, Ex. 8.8):
%     interplanetary_lambert('earth', [1996 11 7 0 0 0], 'mars', [], 309)

if nargin < 5
    error('Specify time of flight in days.');
end

c = constants_curtis();
mu = c.mu_sun;

[R1, V1p, ~] = planet_elements_and_sv(planet1, dep(1), dep(2), dep(3), dep(4), dep(5), dep(6));

if isempty(arr)
    jd_dep = julian_day(dep(1), dep(2), dep(3), dep(4), dep(5), dep(6));
    jd_arr = jd_dep + tof_days;
    [y, m, d, ut] = jd_to_ymd(jd_arr);
    hour = floor(ut);
    minute = floor((ut - hour)*60);
    second = (ut - hour - minute/60)*3600;
    arr = [y, m, d, hour, minute, second];
end

[R2, V2p, ~] = planet_elements_and_sv(planet2, arr(1), arr(2), arr(3), arr(4), arr(5), arr(6));

dt = tof_days * 86400;

% Try prograde and retrograde; keep lower departure v_inf (typical launch min)
[Vdep_p, Varr_p, ext_p] = lambert_universal(R1, R2, dt, mu, 'prograde');
[Vdep_r, Varr_r, ext_r] = lambert_universal(R1, R2, dt, mu, 'retrograde');

vinf_p = norm(Vdep_p - V1p);
vinf_r = norm(Vdep_r - V1p);

if ~ext_p && (ext_r || vinf_p <= vinf_r)
    Vdep = Vdep_p; Varr = Varr_p;
elseif ~ext_r
    Vdep = Vdep_r; Varr = Varr_r;
else
    Vdep = Vdep_p; Varr = Varr_p;
end

vinf_dep = Vdep - V1p;
vinf_arr = Varr - V2p;

out.R1 = R1;
out.R2 = R2;
out.V1_planet = V1p;
out.V2_planet = V2p;
out.V_dep = Vdep;
out.V_arr = Varr;
out.v_inf_dep = norm(vinf_dep);
out.v_inf_arr = norm(vinf_arr);
out.v_inf_dep_vec = vinf_dep;
out.v_inf_arr_vec = vinf_arr;
out.tof_days = tof_days;
out.dep = dep;
out.arr = arr;

end

function [y, m, d, ut] = jd_to_ymd(jd)
% Approximate calendar from Julian day (1901–2099, sufficient for exam).
j = jd + 0.5;
Z = floor(j);
F = j - Z;
if Z < 2299161
    A = Z;
else
    alpha = floor((Z - 1867216.25) / 36524.25);
    A = Z + 1 + alpha - floor(alpha/4);
end
B = A + 1524;
C = floor((B - 122.1) / 365.25);
y = floor(365.25 * C);
D = floor((B - y) / 30.6001);
d = B - y - floor(30.6001 * D);
m = D - 1;
if m > 12, m = m - 12; end
y = C - 4716;
if m > 2, y = y - 1; end
ut = F * 24;
end
