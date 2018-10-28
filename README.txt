
This code accompanies the publication

New software protocols for enabling laboratory based temporal CT

by

Parmesh Gajjar, 
Jakob S. Jorgensen, 
Jose R. A. Godinho, 
Chris G. Johnson, 
Andrew Ramsey, and 
Philip J. Withers

Review of Scientific Instruments 89, 093702 (2018); 
DOI: 10.1063/1.5044393
View online: https://doi.org/10.1063/1.5044393
Published by the American Institute of Physics

The code has been developed and tested in MATLAB R2017a on Ubuntu 16.04
by Jakob S. Jorgensen, University of Manchester, UK.
Contact: jakob.jorgensen@manchester.ac.uk

To set up in order to run the code, the following steps should be carried
out, including download of the data:

1. From https://zenodo.org/record/1204088 download the data set
   GoldenRatioDataset.zip an unzip to obtain a directory called 
   GoldenRatioDataset. This is the datapath referred to in the code.

2. From the Github repository holding this code either clone or download 
   zip file to the GoldenRatioDataset directory and unzip to obtain a 
   directory with the code. This directory will be called something like
   TemporalCT-ContinuousGR.Reconstruction; its name is not that important, 
   but it is important that it is placed as a subdirectory in the 
   GoldenRatioDataset, in order to for the pre-specified paths to data 
   etc. be correct.

3. Make sure that the dependencies specified below are satisfied (in 
   practice only the first dependency (the ASTRA Tomography Toolbox) is 
   important for the user to set up, since the other ones are included 
   with the present code.

Once setup, the code will run CGLS reconstruction as described in the 
paper. There are three main steps to run, contained in separate scripts 
all starting with "run_":

1. run_determine_offsets.m 
   This will estimate individual horizontal offsets to apply to each 
   projection to compensate for misalignment during the scan. This step 
   produces the mat-file offsets.mat to be loaded in the next step. The 
   file offsets.mat has also been included with the code, so this first
   step can be skipped, but code is provided for completeness.

2. run_reconstruction.m
   This is the main file in which the specified reconstruction(s) are run 
   and saved to disk.
   
3. run_show_reconstruction.m
   This will load saved reconstructions and display ortho slices.

The rest of the files are utility functions or third-party code.

The code have the following dependencies:

1. Assumes that the ASTRA Tomography Toolbox 1.8 is installed and on 
   MATLAB path. Please see: http://www.astra-toolbox.com/

2. Modified version of tools provided by the SophiaBeads dataset
   project codes that are available from
   https://sophilyplum.github.io/sophiabeads-datasets/
   The modified version is included with the present code.

3. Modified version of CGLS algorithm cgls.m from Regularization Tools 4.1 
   by Per Christian Hansen, available from 
   http://www.imm.dtu.dk/~pcha/Regutools/
   The modified version is included with the present code.

4. Matlab tool splinefit Jonas Lundgren, splinefit@gmail.com.
   The code is obtained from 
   https://uk.mathworks.com/matlabcentral/fileexchange/13812-splinefit
   and has been included with the present code for convenience.

Other requirements:

The code makes heavy use of GPU acceleration through the ASTRA Tomography 
Toolbox and it is essential that (at least) one NVIDIA GPU is available.