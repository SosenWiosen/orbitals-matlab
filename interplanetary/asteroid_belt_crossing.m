function belt = asteroid_belt_crossing(R1, V1, R2, V2, mu_sun, AU)
%ASTEROID_BELT_CROSSING  Check transfer orbit vs belt 2.1–3.3 AU (Exam Task 7).
%
%   belt = asteroid_belt_crossing(R1, V1, R2, V2, mu_sun, AU)

R1 = R1(:);
V1 = V1(:);

r1 = norm(R1);
v1 = norm(V1);

eps = v1^2/2 - mu_sun/r1;
a = -mu_sun / (2*eps);

e_vec = ((v1^2 - mu_sun/r1)*R1 - dot(R1, V1)*V1) / mu_sun;
e = norm(e_vec);

r_p = a * (1 - e);
r_a = a * (1 + e);

belt.rp_km = r_p;
belt.ra_km = r_a;
belt.rp_AU = r_p / AU;
belt.ra_AU = r_a / AU;
belt.a_AU = a / AU;
belt.e = e;

inner = 2.1 * AU;
outer = 3.3 * AU;

belt.crosses = (r_p < outer) && (r_a > inner);
belt.depth_AU = min(outer, r_a) - max(inner, r_p);
if belt.depth_AU < 0
    belt.depth_AU = 0;
end

end
