function setup()
% add interplanetary + utils to path — run once after cd matlab

p = fileparts(mfilename('fullpath'));
addpath(fullfile(p, 'utils'));
addpath(fullfile(p, 'interplanetary'));
addpath(fullfile(p, 'exercises'));

end
