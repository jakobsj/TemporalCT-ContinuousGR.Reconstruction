
% This is the main script in which the specified reconstruction(s) are run 
% and saved to disk.


%% Set paths to data directory and output.

data_pathname = fullfile(...
    '..',...
    'RawUncorrectedData',...
    'goldenangleTestFast_real_2018-01-11 12-28-38-PM');

data_filename = 'goldenangleTestFast_real';

shading_pathname = fullfile(...
    '..',...
    'ShadingCorrectionFiles',...
    'ShadingCorrection_120kV67uA_2018-01-11 12-23-04-PM');

flat_filename = 'Flat_120kV67uA.tif';
dark_filename = 'Dark_120kV67uA.tif';

horz_cor_file = 'offsets.mat';

output_path = 'output';

%% Include third party code and specify which GPUs to use with ASTRA

% Include tools modified from the SophiaBeads dataset project.
addpath(genpath('sophiabeads_modified/'))

% Ensure ASTRA Tomography Toolbox 1.8 is installed and on MATLAB path.
% Refer to the ASTRA documentation, see  http://www.astra-toolbox.com/


% Specify which GPUs to use with ASTRA in case non-default setup is
% desired. For the results in the paper we used GPUs 0 and 1. For default
% behaviour, simply comment this line out.
astra_mex('set_gpu_index', [0 1]);

%% Set parameters.

% Number of projections to use in a reconstruction.
numproj_list = 100;  % Values used in paper: 100, 600, 2000.

% Index of central projection to use, thus specifying the time of the
% reconstruction. For example if 2000 projections are used and the central
% projection is set to 1500, then projection indices 501--2500 are used. In
% the paper values used are:
% For  100 projections:  100:100:4200.
% For  600 projections:  300:100:4000.
% For 2000 projections: 1000:100:3300.
projidx1 = 1100; 

% Number of CGLS iterations to run. In the paper 50 iterations was used.
iterations = 50;

% Whether to save results.
do_save = true;

% Center-of-rotation correction, i.e., horizontal offset. List of values
% possible and will be looped over. Value used in paper: -4.6.
center_offset_list = -4.6;

% Rotation axis tilt (in fact roll, not precesion) correction. List of
% values possible and will be looped over. Value used in paper: -0.16.
tilt_angle_list = -0.16;

% Subset of slices to be saved (to save space).
slices_to_save = 151:1650;

% Additional horizontal correction factor manually found as optimal at 2.8.
do_horz_cor_list = 2.8;
do_horz = true;
if do_horz
    load(horz_cor_file)
end

%% Main loop over chosen parameters and do CGLS reconstruction.

for ll = 1:length(do_horz_cor_list)
    do_horz_cor = do_horz_cor_list(ll)
    
    for jj = 1:length(center_offset_list)
        center_offset = center_offset_list(jj);
        
        for ii = 1:length(tilt_angle_list)
            tilt_angle = tilt_angle_list(ii);
            
            for k = 1:length(projidx1)
                
                for j = 1:length(numproj_list)
                    projidx1(k)
                    numproj = numproj_list(j)
                    
                    % Set the indices of projections to use.
                    projidx = ...
                        projidx1(k)-numproj/2+1:projidx1(k)+numproj/2;
                    
                    % Read data.
                    [data,geom] = read_data(...
                        projidx,...
                        data_pathname,...
                        data_filename,...
                        shading_pathname,...
                        flat_filename,...
                        dark_filename);
                    
                    % Convert data to ASTRA format and apply individual
                    % horizontal corrections if desired.
                    if ~do_horz
                        [data, proj_geom, vol_geom] = geom3astra_vec(...
                            data, geom, center_offset, tilt_angle);
                    else
                        [data, proj_geom, vol_geom] = geom3astra_vec(...
                            data, geom, center_offset, tilt_angle, ...
                            do_horz_cor+offsets(projidx));
                    end
                    
                    % Get ready for CGLS: Set up opTomo operator and
                    % vectorize data.
                    W = opTomo('cuda',proj_geom,vol_geom);
                    size_DATA = size(data);
                    data = data(:);
                    
                    % Run CGLS.
                    xcgls_astra = cgls_simple(W,data,iterations);
                    
                    % Reshape to volume.
                    size_X = [vol_geom.GridRowCount,...
                        vol_geom.GridColCount,...
                        vol_geom.GridSliceCount];
                    xcgls_astra = reshape(xcgls_astra,size_X);
                    
                    % Save if desired.
                    savefilename = sprintf('cgls_%04d_%04d',...
                        projidx1(k),numproj);
                    savefilename = strrep(savefilename,'.','p');
                    if do_save
                        write_vol(xcgls_astra(:,:,slices_to_save),...
                            output_path, savefilename);
                        clear data xcgls_astra
                    end
                end
            end
        end
    end
end
