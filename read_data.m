function [data,geom] = read_data(projidx,pathname,filename,shading_path,flat_file,dark_file)
% Load projections specified in projidx using given paths to data and flat
% and dark field and apply flat and dark field correction as well as
% negative log tranform.


% Set fixed parameters.
geom_type = '3D'; 
slices = 2000; 
pixels_nY = 1720;
pixels_nZ = 2000;

% Load and apply corrections to data.
[data_raw, geom] = load_nikon(pathname, filename, geom_type, [], projidx);

% Undo scaling and negative log done when loaded, in order to apply dark
% and flat field corrections manually.
data_raw = 60000*exp(-data_raw);

% Load and apply dark and flat field.
flatimfull = rot90(single(imread(fullfile(shading_path,flat_file))),-1);
darkimfull = rot90(single(imread(fullfile(shading_path,dark_file))),-1);
data_raw = (data_raw - darkimfull) ./ (flatimfull - darkimfull);

% Cut down data.
[data_raw,geom] = cutDown_data(data_raw, geom, geom_type, slices, ...
    pixels_nY,pixels_nZ);

% Reverse angles and negative log transform.
geom.angles = -geom.angles;
data = -log(data_raw);
