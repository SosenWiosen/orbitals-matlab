function fb = flyby_patch(Vp, Vin, rp, mu, leading)
% flyby in planet frame, then back to heliocentric (sec 8.9)

Vp = Vp(:);
Vin = Vin(:);

vinf_in = Vin - Vp;
vinf = norm(vinf_in);

e = 1 + rp * vinf^2 / mu;
delta = 2 * asin(1/e);

k = cross(vinf_in, Vp);
if norm(k) < 1e-10
    k = [0;0;1];
end
k = k / norm(k);

sgn = -1;
if ~leading
    sgn = 1;
end

vinf_out = rodrigues(vinf_in, k, sgn*delta);
Vout = Vp + vinf_out;

fb.v_inf = vinf;
fb.v_inf_out = norm(vinf_out);
fb.delta_deg = rad2deg(delta);
fb.e = e;
fb.V_out = Vout;
fb.dV_sun = norm(Vout - Vin);
fb.v_inf_out_vec = vinf_out;

end

function v = rodrigues(v, k, a)
v = v*cos(a) + cross(k,v)*sin(a) + k*dot(k,v)*(1-cos(a));
end
