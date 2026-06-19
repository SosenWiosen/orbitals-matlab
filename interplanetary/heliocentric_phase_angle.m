function phi_deg = heliocentric_phase_angle(R1, R2)
%HELIOCENTRIC_PHASE_ANGLE  Curtis Eq. (8.7) — phi = theta2 - theta1 in ecliptic plane.

x1 = R1(1); y1 = R1(2);
x2 = R2(1); y2 = R2(2);
phi_deg = rad2deg(atan2(y2, x2) - atan2(y1, x1));
phi_deg = mod(phi_deg + 180, 360) - 180;

end
