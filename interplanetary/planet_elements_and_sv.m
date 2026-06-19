function [R, V, el] = planet_elements_and_sv(planet, year, month, day, hour, minute, second)
%PLANET_ELEMENTS_AND_SV  Algorithm 8.1 — planet state at epoch (Curtis Ch. 8.10).
%
%   [R, V, el] = planet_elements_and_sv('earth', 2003, 8, 27, 12, 0, 0)
%
%   planet — name: mercury, venus, earth, mars, jupiter, saturn, uranus, neptune
%   R, V   — heliocentric ecliptic position (km) and velocity (km/s)
%   el     — struct with a, e, i, RA, w, theta, h (km^2/s)

if nargin < 7, second = 0; end
if nargin < 6, minute = 0; end
if nargin < 5, hour = 0; end

c = constants_curtis();
mu = c.mu_sun;
AU = c.AU;

planet = lower(strtrim(planet));
tab = c.table81.(planet);
a0 = tab(1); da = tab(2);
e0 = tab(3); de = tab(4);
i0 = tab(5); di = tab(6);
O0 = tab(7); dO = tab(8);
p0 = tab(9); dp = tab(10);   % varpi (longitude of perihelion)
L0 = tab(11); dL = tab(12);

jd = julian_day(year, month, day, hour, minute, second);
T0 = (jd - 2451545.0) / 36525;

a = (a0 + da*T0) * AU;
e = e0 + de*T0;
i = mod(i0 + di*T0, 360);
RA = mod(O0 + dO*T0, 360);
varpi = mod(p0 + dp*T0, 360);
L = mod(L0 + dL*T0, 360);

w = mod(varpi - RA, 360);
M = mod(L - varpi, 360);
M = deg2rad(M);

E = kepler_E(M, e);
E = mod(E, 2*pi);

tan_half = sqrt((1+e)/(1-e)) * tan(E/2);
theta = mod(2*atan(tan_half), 2*pi);
theta = rad2deg(theta);

h = sqrt(mu * a * (1 - e^2));

[R, V] = heliocentric_coe_to_sv(h, e, RA, i, w, theta, mu);

el.a = a;
el.e = e;
el.i = i;
el.RA = RA;
el.w = w;
el.theta = theta;
el.h = h;
el.varpi = varpi;
el.M = rad2deg(M);

end
