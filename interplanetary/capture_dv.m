function dv = capture_dv(v_inf, mu, rp, e_cap)
% arrival hyperbola -> capture orbit at rp (eq 8.60)

v_hyp = sqrt(v_inf^2 + 2*mu/rp);
v_cap = sqrt(mu/rp * (1 + e_cap));
dv = v_hyp - v_cap;

end
