function [delta_deg, e] = flyby_delta(rp, v_inf, mu)
%FLYBY_DELTA  Turn angle at flyby (Curtis Eq. 8.54).

e = 1 + rp * v_inf^2 / mu;
delta_deg = rad2deg(2 * asin(1/e));

end
