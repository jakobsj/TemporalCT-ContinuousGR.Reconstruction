
% This script will load saved reconstructions and display ortho slices.


%% Set path to directory where reconstructions have been saved.

savefilepath = 'output';

%% Parameters to set.

% Which time instance ie which projection was central. A list (vector) can
% be specified to be looped over.
projidx1 = [1100];

% How many projections used for reconstruction. A list (vector) can be
% specified to be looped over.
numproj = [100,600,2000];

%% Fixed parameters.

% Dimension of volume
size_X = [1720,1720,1500];

% Color range for display
ca = [0,2e-3];

%% Load and display
% Loop over time instances and number of projections and load and display
% ortho slices of reconstruction.
for k = 1:length(projidx1)
    for l = 1:length(numproj)
        
        % Construct filename
        savefilename = sprintf('cgls_%04d_%04d',...
            projidx1(k),numproj(l))
        savefilename = strrep(savefilename,'.','p');
        
        % Read reconstructed volume
        vol = read_vol(savefilepath,...
            savefilename,'',size_X);
        
        % Display central ortho slices
        figure
        
        subplot(2,3,1)
        im1 = vol(:,:,end/2);
        imagesc(im1)
        axis image off
        colormap gray
        caxis(ca)
        
        subplot(2,3,2)
        im2 = rot90(squeeze(vol(:,end/2,:)));
        imagesc(im2)
        axis image off
        colormap gray
        caxis(ca)
        title(sprintf(...
            'Central projection: %d, number of projections: %d',...
            projidx1(k), numproj(l)))
        
        subplot(2,3,3)
        im3 = rot90(squeeze(vol(end/2,:,:)));
        imagesc(im3)
        axis image off
        colormap gray
        caxis(ca)
        
        subplot(2,3,4)
        imagesc(im1(611:1110,611:1110))
        axis image off
        colormap gray
        caxis(ca)
        
        subplot(2,3,5)
        imagesc(im2(501:1000,611:1110))
        axis image off
        colormap gray
        caxis(ca)
        title('Zooms to central 500x500 pixels of the above')
        
        subplot(2,3,6)
        imagesc(im3(501:1000,611:1110))
        axis image off
        colormap gray
        caxis(ca)
        
        % Update screen before next load.
        drawnow
    end
end