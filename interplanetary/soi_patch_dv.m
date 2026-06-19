function patch = soi_patch_dv(V_before, V_after, V_planet)
%SOI_PATCH_DV  Impulsive SOI burn to match the next heliocentric leg.
%
%   patch = soi_patch_dv(V_before, V_after, V_planet)
%
%   V_before — heliocentric velocity before patch (e.g. after flyby)
%   V_after  — target heliocentric velocity (next Lambert departure)
%   V_planet — planet heliocentric velocity at the node
%
%   Returns dv (km/s) and v_inf mismatch magnitudes in the planet frame.

V_before = V_before(:);
V_after = V_after(:);
V_planet = V_planet(:);

dv_vec = V_after - V_before;

patch.dv = norm(dv_vec);
patch.dv_vec = dv_vec;

vinf_before = V_before - V_planet;
vinf_after = V_after - V_planet;

patch.v_inf_before = norm(vinf_before);
patch.v_inf_after = norm(vinf_after);
patch.v_inf_gap = abs(patch.v_inf_after - patch.v_inf_before);

end
