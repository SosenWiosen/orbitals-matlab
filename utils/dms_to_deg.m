function deg = dms_to_deg(degrees, minutes, seconds, hemisphere)
%DMS_TO_DEG Convert degrees-minutes-seconds to decimal degrees.
%
%   deg = dms_to_deg(18, 3, 0, 'E')   % east longitude
%   deg = dms_to_deg(118, 15, 0, 'W') % west longitude (negative east)

if nargin < 3, seconds = 0; end
if nargin < 4, hemisphere = 'E'; end

deg = abs(degrees) + abs(minutes) / 60 + abs(seconds) / 3600;

switch upper(strtrim(hemisphere))
    case {'E', 'N', '+'}
        % east longitude / north latitude
    case {'W', 'S', '-'}
        deg = -deg;
    otherwise
        error('hemisphere must be E, W, N, S, +, or -');
end

end
