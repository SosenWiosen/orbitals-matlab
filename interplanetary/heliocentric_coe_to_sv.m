function [R, V] = heliocentric_coe_to_sv(h, e, RA, incl, w, theta, mu)
%HELIOCENTRIC_COE_TO_SV  Algorithm 4.5 — heliocentric ecliptic frame (Ch. 8).
%
%   RA     — right ascension of ascending node Omega (deg)
%   incl   — inclination i (deg)
%   w      — argument of perihelion omega (deg)
%   theta  — true anomaly (deg)

RA = deg2rad(RA);
incl = deg2rad(incl);
w = deg2rad(w);
theta = deg2rad(theta);

r = h^2 / mu / (1 + e*cos(theta));
vr = mu/h * e*sin(theta);
vt = mu/h * (1 + e*cos(theta));

R_pqw = [r*cos(theta); r*sin(theta); 0];
V_pqw = [vr*cos(theta) - vt*sin(theta); vr*sin(theta) + vt*cos(theta); 0];

cO = cos(RA); sO = sin(RA);
ci = cos(incl); si = sin(incl);
cw = cos(w); sw = sin(w);

Q = [ cO*cw - sO*sw*ci,  -cO*sw - sO*cw*ci,  sO*si;
      sO*cw + cO*sw*ci,  -sO*sw + cO*cw*ci, -cO*si;
      sw*si,              cw*si,              ci];

R = Q * R_pqw;
V = Q * V_pqw;

end
