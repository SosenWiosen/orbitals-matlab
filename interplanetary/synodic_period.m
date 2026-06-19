function T_syn = synodic_period(T1, T2)
%SYNODIC_PERIOD  Curtis Eq. (8.10).

T_syn = T1 * T2 / abs(T1 - T2);

end
