
% This script estimates individual horizontal offsets to apply to each 
% projection to compensate for misalignment during the scan. This step 
% produces the mat-file offsets.mat to be loaded in the next step. The
% file offsets.mat has also been included with the code, so this first
% step can be skipped, but code is provided for completeness.


%% Paths to set.

% Add utility splinefit to path
addpath splinefit

% Path to data directory.
pathname = fullfile(...
    '..',...
    'RawUncorrectedData',...
    'goldenangleTestFast_real_2018-01-11 12-28-38-PM');

%% Filenames and parameters.

% File with time stamp of angles.
angtimefile = 'goldenangleTestFast_real.angTime';

% File string format.
filestr = 'goldenangleTestFast_real_%04d.tif';

% Image dimensions and (center) row of image to use for offset estimation.
rowidx = 1000;
numprojs = 4394;
imsize = 2000;

%% Load central row of all projections into sinogram array.

% Preallocate
sino = zeros(imsize,numprojs);

% Loop over angles, read image and store central row as column of sino.
for k = 1:numprojs
    k
    im = imread(fullfile(pathname,sprintf(filestr,k)));
    sino(:,k) = im(rowidx,:);
end

%% Load and sort angles, saving sorting index for later sort of sinogram.

% Load angles.
[A,angles,C,h,m,s,ms] = textread(fullfile(pathname,angtimefile),...
    '%d:\t%f %10c\t%2d:%2d:%2d.%3d','headerlines',1);

% Sort angles.
[angles_sorted, sort_idx] = sort(angles);

%% Determine individual offsets.

% Region at top and bottom of sinogram where transition to air happens.
top_idx = 131:210;
bot_idx = 1791:1870;

% Resort sinograms by angle which should cause sinogram to become smooth,
% apart from offsets to be estimated. Fit spline to top and bottom curve
% and compute individual offsets relative to the spline at top and bottom.
offsets_top = compute_deviations(sino,sort_idx,top_idx,false);
offsets_bot = compute_deviations(-sino,sort_idx,bot_idx,false);

% Simply average offsets at top and bottom for final offsets to use.
offsets = 0.5*(offsets_top + offsets_bot);

% Save for use in reconstruction.
save offsets.mat offsets