function [dv1, dv2, dv_total] = hohmann_planet(mu, r1, r2)
%HOHMANN_PLANET  Ch. 6 Hohmann between coplanar circular orbits about a planet/moon.
%
%   Used for Saturn parking -> Titan (exam mission leg).

r_inner = min(r1, r2);
r_outer = max(r1, r2);
a = (r_inner + r_outer) / 2;

v1 = sqrt(mu / r_inner);
v2 = sqrt(mu / r_outer);
vt1 = sqrt(2*mu/r_inner - mu/a);
vt2 = sqrt(2*mu/r_outer - mu/a);

if r1 <= r2
    dv1 = vt1 - v1;
    dv2 = v2 - vt2;
else
    dv1 = v1 - vt1;
    dv2 = vt2 - v2;
end

dv_total = abs(dv1) + abs(dv2);

end
