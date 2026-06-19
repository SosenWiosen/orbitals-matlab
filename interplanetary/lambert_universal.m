function [V1, V2, extremal] = lambert_universal(R1, R2, dt, mu, direction)
%LAMBERT_UNIVERSAL  Curtis Algorithm 5.2 / Appendix D.11 (lambert.m).
%
%   [V1, V2, extremal] = lambert_universal(R1, R2, dt, mu, direction)
%
%   R1, R2  — position vectors (km), 3x1
%   dt      — time of flight (s), positive
%   mu      — gravitational parameter (km^3/s^2)
%   direction — 'prograde'/'pro' or 'retrograde'/'retro' (default prograde)

R1 = R1(:);
R2 = R2(:);

r1 = norm(R1);
r2 = norm(R2);

c12 = cross(R1, R2);
theta = acos(max(-1, min(1, dot(R1, R2) / (r1*r2))));

if nargin < 5 || isempty(direction)
    direction = 'prograde';
end

is_pro = any(strcmpi(direction, {'prograde', 'pro'}));
is_retro = any(strcmpi(direction, {'retrograde', 'retro'}));

if is_retro
    if c12(3) >= 0
        theta = 2*pi - theta;
    end
elseif is_pro
    if c12(3) <= 0
        theta = 2*pi - theta;
    end
else
    if c12(3) <= 0
        theta = 2*pi - theta;
    end
end

A = sin(theta) * sqrt(r1*r2 / (1 - cos(theta)));

z = -100;
while true
    if y_z(z, r1, r2, A) <= 0
        z = z + 0.1;
        continue;
    end
    if F(z, r1, r2, A, dt, mu) >= 0
        break;
    end
    z = z + 0.1;
end

tol = 1e-8;
nmax = 5000;
ratio = 1;
n = 0;
extremal = false;

while abs(ratio) > tol && n <= nmax
    n = n + 1;
    dF = dFdz(z, r1, r2, A, mu);
    if abs(dF) < 1e-14
        extremal = true;
        break;
    end
    ratio = F(z, r1, r2, A, dt, mu) / dF;
    z = z - ratio;
end

if n >= nmax
    extremal = true;
end

y = y_z(z, r1, r2, A);
f = 1 - y/r1;
g = A * sqrt(y/mu);
gdot = 1 - y/r2;

V1 = (R2 - f*R1) / g;
V2 = (gdot*R2 - R1) / g;

end

function val = y_z(z, r1, r2, A)
val = r1 + r2 + A*(z*S(z) - 1) / sqrt(C(z));
end

function val = F(z, r1, r2, A, t, mu)
y = y_z(z, r1, r2, A);
val = (y/C(z))^1.5 * S(z) + A*sqrt(y) - sqrt(mu)*t;
end

function val = dFdz(z, r1, r2, A, mu)
y = y_z(z, r1, r2, A);
if abs(z) < 1e-12
    val = sqrt(2)/40 * y^1.5 + A/8 * (sqrt(y) + A*sqrt(1/(2*y)));
else
    val = (y/C(z))^1.5 * (1/(2*z)*(C(z) - 3*S(z)/(2*C(z))) + 3*S(z)^2/(4*C(z))) ...
        + A/8 * (3*S(z)/C(z)*sqrt(y) + A*sqrt(C(z)/y));
end
end

function val = C(z)
if z > 0
    val = (1 - cos(sqrt(z))) / z;
elseif z < 0
    val = (cosh(sqrt(-z)) - 1) / (-z);
else
    val = 1/2;
end
end

function val = S(z)
if z > 0
    sz = sqrt(z);
    val = (sz - sin(sz)) / (sz^3);
elseif z < 0
    sz = sqrt(-z);
    val = (sinh(sz) - sz) / (sz^3);
else
    val = 1/6;
end
end
