function angle = wrap360(angle)
%WRAP360 Reduce angles to the range [0, 360) degrees.

angle = mod(angle, 360);

if angle < 0
    angle = angle + 360;
end

end
