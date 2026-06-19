function [dv_total, dv] = multiburn_leo_escape(v_inf, mu, rp, Ra1, Ra2)
% three prograde burns at perigee, then escape (eq 8.40)

vc = sqrt(mu / rp);

a1 = (rp + Ra1) / 2;
v1 = sqrt(2*mu/rp - mu/a1);
dv1 = v1 - vc;

a2 = (rp + Ra2) / 2;
v2 = sqrt(2*mu/rp - mu/a2);
dv2 = v2 - v1;

vp = sqrt(v_inf^2 + 2*mu/rp);
dv3 = vp - v2;

dv = [dv1; dv2; dv3];
dv_total = sum(dv);

end
