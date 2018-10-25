function [data, proj_geom_vec, vol_geom] = geom3astra_vec(data, geom, ...
    center_offset, tilt_angle,horz_cor)

if nargin < 5 || isempty(horz_cor)
    horz_cor = zeros(size(geom.angles));
end

%% Extract from geom structure.

numbins_horz = geom.dets.ny;  % number of detector elements (bins)
N = geom.voxels(1); % number of pixels on each side of object
numprojs = length(geom.angles); % number of projections (views)

% Relative size of detector pixel to object pixel
det_width = diff(geom.dets.y(1:2)) /geom.voxel_size(1);

% Number of detector pixels
det_count_horz = geom.dets.ny;

% The angles
angles = -geom.angles;

% Source to centre of rotation distance in units of object pixels
source_origin = abs(geom.source.x) / geom.voxel_size(1);

% Centre of rotation to detector distance in units of object pixels
origin_det = abs(geom.dets.x) / geom.voxel_size(1);

% Number of slices in z-direction
slices = geom.dets.nz;


%% Reshape and permute data to fit ASTRA ordering.
data = permute(reshape(data,numbins_horz,slices,numprojs),[1,3,2]);


%% Set up ASTRA volume geometry and preliminary projection geometry.

vol_geom = astra_create_vol_geom(N, N, slices);
proj_geom = astra_create_proj_geom('cone', det_width, det_width, ...
   slices, det_count_horz, angles, source_origin, origin_det);


%% Set up projection vector geometry to correct centering and tilt.

% Rotation matrix for projections (about the z axis)
Rz = @(THETA) [ cos(THETA), -sin(THETA), 0;
                sin(THETA),  cos(THETA), 0;
                0         ,  0         , 1];

% Unrotated (angular position 0 degrees) vectors:
% source pos, detector pos, detector orientation.
s0 = [0; -proj_geom.DistanceOriginSource  ; 0];
d0 = [0;  proj_geom.DistanceOriginDetector; 0];
u0 = [proj_geom.DetectorSpacingX; 0; 0];
v0 = [0; 0; proj_geom.DetectorSpacingY];

% Tilt correction. Rotate u0 and v0 about the y-axis. Note that this is
% positive direction when viewed from POSITIVE y-axis.
Ry = @(THETA) [ cos(THETA), 0, sin(THETA);
                0         , 1, 0;
               -sin(THETA), 0, cos(THETA)];
u0 = Ry(deg2rad(tilt_angle))*u0;
v0 = Ry(deg2rad(tilt_angle))*v0;

% Correct for center offset
s0 = s0 + [center_offset; 0; 0];
d0 = d0 + [center_offset; 0; 0];

% Initialise vectors array to hold geometry specification for each
% projection, see ASTRA documention.
vectors = zeros(12,length(angles));

% Loop over all projections and populate vectors array.
for i = 1:length(angles)
    
    % Current rotation matrix
    Rzi = Rz(proj_geom.ProjectionAngles(i));
    
    % Source position.
    vectors(1:3,i) = Rzi*(s0+horz_cor(i));
    
    % Center of detector position.
    vectors(4:6,i) = Rzi*(d0+horz_cor(i));
    
    % Vector from detector pixel (0,0) to (0,1).
    vectors(7:9,i) = Rzi*u0;
    
    % Vector from detector pixel (0,0) to (1,0).
    vectors(10:12,i) = Rzi*v0;
end

% Transpose and create projection vector geometry.
vectors = vectors';
proj_geom_vec = astra_create_proj_geom('cone_vec',  slices, ...
    det_count_horz, vectors);