function [data, geom] = load_nikon(pathname, filename, geom_type, slice,projidx)
%LOAD_NIKON
% Function loads the Nikon XTek data and the corresponding cone beam
% machine geometry.
%
% INPUT:
%   pathname: Name of path where the files are stored.
%   filename: Name of files to load (name of .xtekct file without the
%             extension).
%   geom_type: String to determine whether to load 2D or 3D data.
%   slice: The horizontal slice set as the centre of the loaded data.
%          Default value is set as the centre of the full volumetric data.
%
% OUTPUT:
%   data: Returned Nikon XTek data in single format.
%   geom: Returned geometry structure array.
%
% Copyright (c) 2015 Sophia Bethany Coban
% Code is available via the SophiaBeads Datasets project.
% University of Manchester.

%% Quick error checking:

%pathname has to point to a folder:
%pathname has to point to a folder:
if ispc
    sla='\';
    if ~strcmp(pathname(end),sla)
        pathname = [pathname sla]; % only in windows...
        fprintf('WARNING: The input string pathname has to point to a folder. String has now been modified.\n');
    end
else
    sla='/';
    if ~strcmp(pathname(end),sla)
        pathname = [pathname sla];
        fprintf('WARNING: The input string pathname has to point to a folder. String has now been modified.\n');
    end
end
%% Reading the .xtekct file:

fid = fopen([pathname filename '.xtekct']);  % Open the .xtekct file.

% Read parameters into cell array of strings:
params = textscan(fid, '%s %s', 'Delimiter', '=', 'HeaderLines', 1, 'CommentStyle', '[');

fclose(fid); % closing the file.

%% Extract relevant information from the .xtekct file:

ind = strcmp('SrcToObject', params{1});
SrcToObject = str2double(params{2}(ind));

ind = strcmp('SrcToDetector', params{1});
SrcToDetector = str2double(params{2}(ind));

ind = strcmp('DetectorPixelsX', params{1});
DetectorPixelsX = str2double(params{2}(ind));

ind = strcmp('DetectorPixelsY', params{1});
DetectorPixelsY = str2double(params{2}(ind));

ind = strcmp('DetectorPixelSizeX', params{1});
DetectorPixelSizeX = str2double(params{2}(ind));

ind = strcmp('DetectorPixelSizeY', params{1});
DetectorPixelSizeY = str2double(params{2}(ind));

ind = strcmp('Projections', params{1});
nProjections = str2double(params{2}(ind));

ind = strcmp('VoxelSizeX', params{1});
VoxelSize = str2double(params{2}(ind));

%%
if nargin < 5 || isempty(projidx)
    projidx = 1:nProjections;
end

%% Load the projection data:

if nargin<4 || isempty(slice) % Default slice is the centre slice of the volumetric data.
    sinoFile = [pathname 'CentreSlice' sla 'Sinograms' sla filename '_' dec2base(1,10,4) '.tif'];
    if exist(sinoFile, 'file') == 2 % Check if sinogram file exists!
        slice = 0;
    else % if no sinogram file, define default slice to be read from 3D data.
        slice = floor(DetectorPixelsY/2);
    end
end

if strcmp(geom_type,'2D')
    [data,geom]=data_geom_2D(pathname,filename,DetectorPixelsX,nProjections,slice,sla);
elseif strcmp(geom_type,'3D')
    [data,geom]=data_geom_3D(pathname,filename,DetectorPixelsX,DetectorPixelsY,DetectorPixelSizeY,projidx);
else
    disp('Warning: Unrecognised geom_type. Consider only 2D or 3D');
end

% Final touches.
data = single(data); % Convert to single precision
data = data/60000; % this is the max value for 16bit integer
data = -log(data);

%% Set up the Cone Beam geometry:

geom.geom_type = geom_type; % Useful for error checking later...

% write source and detector coordinate values into geom structure array
geom.source.x = -SrcToObject; % Object is at the origin.
geom.source.y = 0;
geom.source.z = 0;

geom.dets.x = SrcToDetector-SrcToObject; % Distance between object to detector.
geom.dets.y = transpose(DetectorPixelSizeX*((-(DetectorPixelsX-1)/2):((DetectorPixelsX-1)/2)));
geom.dets.ny = DetectorPixelsX;

geom.d_sd = SrcToDetector; % Distance between source to detector.

% Load in the angle information
if exist([pathname '_ctdata.txt'],'file')
    temp = importdata([pathname '_ctdata.txt'], '\t', 3); % CONTINUOUS SCAN
    angles = temp.data(:,2);
    flip = false;
elseif exist([pathname filename '.ang'],'file')
    temp = importdata([pathname filename '.ang'], '\t', 1); % STOP/START SCAN
    angles = temp.data(:,1);
    flip = true;
end

geom.angles = (angles(projidx)-90)*pi/180; % Convert angles to radians.
clear temp angles

% If the angles are decreasing, flip upside down.
if flip
    geom.angles = -geom.angles;
    %geom.angles = geom.angles(end:-1:1);
end

% Default values for the voxel space (these may change later.)
geom.voxel_size = VoxelSize*[1 1 1];
geom.image_offset = [0 0 0];

end


%% Subfunctions for 2D and 3D geometry setup and data loading.

function [data,geom]=data_geom_2D(pathname,filename,DetectorPixelsX,nProjections,slice,sla)


geom.dets.z = 0.0;
geom.dets.nz = 1;

data = uint16(zeros(DetectorPixelsX, nProjections));
if slice == 0 % Default slice recon for 2D is the centre slice, read straight from the sinogram file (if it exists).
    data = imread([pathname 'CentreSlice' sla 'Sinograms' sla filename '_' dec2base(1,10,4) '.tif'])';
else % User has the option to pick a different slice if 3D data is available.
    for i = 1:nProjections
        fprintf('Loading proj %d of %d...\n', i, nProjections);
        tmp_data = imread([pathname filename '_' dec2base(i,10,4) '.tif'])';
        data(:,i) = tmp_data(:,slice);
    end
end

geom.voxels = [DetectorPixelsX DetectorPixelsX 1]; % Volume size in 2D.

end

function [data,geom]=data_geom_3D(pathname,filename,DetectorPixelsX,DetectorPixelsY,DetectorPixelSizeY,projidx)

geom.dets.z = transpose(DetectorPixelSizeY*((-(DetectorPixelsY-1)/2):((DetectorPixelsY-1)/2)));
geom.dets.nz = DetectorPixelsY;

% Indicate where we are.
%h = waitbar(0,'Loading projections...');
data = zeros(DetectorPixelsX, DetectorPixelsY, length(projidx),'uint16');
for i = 1:length(projidx)
    fprintf('Loading proj %d of %d...\n', i, length(projidx));
    data(:,:,i) = imread([pathname filename '_' dec2base(projidx(i),10,4) '.tif'])';
    %waitbar(i/nProjections,h,['Loading projection ' num2str(i)]);
end
%delete(h);

% Image pixels go down, whereas our z voxel ordering goes up, so flip.
data = data(:,end:-1:1,:);

geom.voxels = DetectorPixelsY*[1 1 1]; % Volume size in 3D.

end
