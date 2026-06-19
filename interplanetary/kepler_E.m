function E = kepler_E(M, e)
%KEPLER_E  Solve M = E - e*sin(E) (Curtis Eq. 3.14), M in rad.

M = mod(M, 2*pi);
if e < 1e-10
    E = M;
    return;
end

E = M;
if e > 0.8
    E = pi;
end

for k = 1:50
    f = E - e*sin(E) - M;
    fp = 1 - e*cos(E);
    dE = -f / fp;
    E = E + dE;
    if abs(dE) < 1e-12
        return;
    end
end

end
