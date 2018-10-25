function [data,geom]=cutDown_data(data, geom, geom_type, slices, pixels_nY, pixels_nZ)
%CUTDOWN_DATA
% Function to cut down the SophiaBeads dataset down to the original
% image size (defined during the acquisition of the datasets).
%
% INPUT
%   data: Nikon XTek data in single format.
%   geom: Geometry structure array.
%   geom_type: '2D' or '3D' cone beam geometry.
%   slices: Number of slices in the z-direction.
%
% OUTPUT:
%   data: Cut down Nikon XTek data.
%   geom: Updated geometry structure array.
%
% Copyright (c) 2015 Sophia Bethany Coban
% Code is available via the SophiaBeads Datasets project.
% University of Manchester.


if nargin < 5 || isempty(pixels_nY)
    pixels_nY = 1564;
end

if nargin < 6 || isempty(pixels_nZ)
    pixels_nZ = 1564;
end

% All Nikon XTek datasets have default size 2000 x 2000 x 2000. For the
% SophiaBeads datasets, we are only interested in 1564 x 1564 x slices.
% These numbers are determined during the data acquisition.  
%pixels_nY = pixels;
%pixels_nZ = pixels;

nY = (geom.voxels(1) - pixels_nY)/2; % Cut this many pixels in the Y direction.
nZ = (geom.voxels(2) - pixels_nZ)/2; % Cut this many pixels in the Z direction.

% Update geometry
geom.dets.y = geom.dets.y(nY+1:nY+pixels_nY);
geom.dets.ny = length(geom.dets.y);

if strcmp(geom_type,'3D')
    % Update z pixels in 3D
    geom.dets.z = geom.dets.z(nZ+1:nZ+pixels_nZ);
    geom.dets.nz = length(geom.dets.z);
    % Cut down the 3D data...
    data = data(nY+1:nY+pixels_nY, nZ+1:nZ+pixels_nZ,:);
    geom.voxels = [pixels_nY pixels_nY slices]; % Updated voxel number.
else
    % No z pixels to cut in 2D! Cut down the 2D data...
    data = data(nY+1:nY+pixels_nY,:);
    geom.voxels = [pixels_nY pixels_nY 1]; % Updated voxel number.
end

% Update image offset.
geom.image_offset = -(geom.voxels.*geom.voxel_size)/2;

end
