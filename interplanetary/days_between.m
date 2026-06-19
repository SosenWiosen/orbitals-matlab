function d = days_between(epoch1, epoch2)
%DAYS_BETWEEN  Calendar days between two [y m d h min s] UTC epochs.

jd1 = julian_day(epoch1(1), epoch1(2), epoch1(3), epoch1(4), epoch1(5), epoch1(6));
jd2 = julian_day(epoch2(1), epoch2(2), epoch2(3), epoch2(4), epoch2(5), epoch2(6));
d = jd2 - jd1;

end
