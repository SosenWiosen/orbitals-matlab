function out = hohmann_interplanetary(R1, R2, mu_sun, T1, T2)
%HOHMANN_INTERPLANETARY  Curtis Sec. 8.2 — coplanar circular Hohmann transfer.
%
%   out = hohmann_interplanetary(R1, R2, mu_sun, T1, T2)
%
%   R1, R2   — heliocentric radii of planet 1 (departure) and planet 2 (arrival), km
%   T1, T2   — orbital periods (days); used for phase angle (8.12–8.13). Optional.
%
%   Fields: V1, V2, V_dep, V_arr, dv_dep, dv_arr, dv_total_helio, v_inf_dep, v_inf_arr,
%           a_trans, TOF_days, phi0_deg, phi_f_deg, n1, n2

if R2 < R1
    error('hohmann_interplanetary: use R1 = inner planet, R2 = outer planet.');
end

a = (R1 + R2) / 2;

V1 = sqrt(mu_sun / R1);
V2 = sqrt(mu_sun / R2);

V_dep = sqrt(2*mu_sun/R1) * sqrt(R2 / (R1 + R2));
V_arr = sqrt(2*mu_sun/R2) * sqrt(R1 / (R1 + R2));

dv_dep = V_dep - V1;
dv_arr = V2 - V_arr;

v_inf_dep = dv_dep;
v_inf_arr = dv_arr;

TOF_sec = pi * sqrt(a^3 / mu_sun);
TOF_days = TOF_sec / 86400;

out.V1 = V1;
out.V2 = V2;
out.V_dep = V_dep;
out.V_arr = V_arr;
out.dv_dep = dv_dep;
out.dv_arr = dv_arr;
out.dv_total_helio = dv_dep + dv_arr;
out.v_inf_dep = v_inf_dep;
out.v_inf_arr = v_inf_arr;
out.a_trans = a;
out.TOF_days = TOF_days;
out.TOF_years = TOF_days / 365.25;

if nargin >= 5 && ~isempty(T1) && ~isempty(T2)
    n1 = 2*pi / (T1 * 86400);
    n2 = 2*pi / (T2 * 86400);
    t12 = TOF_sec;
    out.phi0_deg = rad2deg(pi - n2*t12);          % Eq. (8.12)
    out.phi_f_deg = rad2deg(pi - n1*t12);          % Eq. (8.13)
    out.n1 = n1;
    out.n2 = n2;
else
    out.phi0_deg = NaN;
    out.phi_f_deg = NaN;
end

end
