function r_soi = sphere_of_influence(a_orbit, m_planet, m_central)
%SPHERE_OF_INFLUENCE  Curtis Eq. (8.34).

r_soi = a_orbit * (m_planet / m_central)^(2/5);

end
