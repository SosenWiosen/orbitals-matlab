function [dv, vp, vc, e, beta_deg] = departure_dv(v_inf, mu_planet, rp)
%DEPARTURE_DV  Curtis Sec. 8.6 — parking orbit to departure hyperbola (Eq. 8.42).
%
%   [dv, vp, vc, e, beta_deg] = departure_dv(v_inf, mu_planet, rp)
%
%   v_inf      — hyperbolic excess speed (km/s)
%   mu_planet  — planet GM (km^3/s^2)
%   rp         — periapsis radius = parking orbit radius (km)

vc = sqrt(mu_planet / rp);
vp = sqrt(v_inf^2 + 2*mu_planet/rp);
dv = vp - vc;

e = 1 + rp * v_inf^2 / mu_planet;
beta_deg = rad2deg(acos(1/e));

end
