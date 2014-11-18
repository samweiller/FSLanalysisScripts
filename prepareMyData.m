function prm = prepareMyData_MyExperiment
%% Prepare My Data
%  Prepare my data is a gateway script to the pre-analysis pipeline. This
%  is where you will define all of your parameters to be used by subsequent
%  Stages.
% 
%  INSTRUCTIONS
%  Make a COPY of this script and add your parameters. The supporting files
%  are on the MATLAB path for trex, so it can be run from anywhere.
%% Define General Parameters
%  Define the overall experimental params.

prm.projectName = 'AVNA';    % The name of your entire project
prm.subject     = 'VNA01';  % Subject number/ID
prm.MRID        = '0003';   % MR-specific subject number (currently unneccesary) 
prm.subType     = 'Adult';  % Subject type (Adult, Kid, Patient)
prm.expInitials = 'SKW';    % Experimenter's initials
prm.rawLocation = sprintf('/Volumes/Apollo/DilksStudies/FERN-DILKSDilksStudies/%s*', prm.subject);
prm.destination = sprintf('/Volumes/Zeus/%s/%s', prm.projectName, prm.subject);
prm.logFiles    = sprintf('/Volumes/Zeus/%s/logs', prm.projectName);

%% Define MR Specific Parameters
%  Define the experiment-specific parameters.

prm.experiment  = 'VNA';
prm.infoFile    = sprintf('/Volumes/Zeus/%s/logs/%s_%s_params.txt', prm.projectName, prm.subject, prm.experiment);

prm.anatomicalAcq   = [2];

prm.partialTest     = [5];
prm.wholeBrainTest  = [7];

prm.fieldMapPartialMagnitude = [8];
prm.fieldMapPartialPhase     = [9];
prm.fieldMapWholeMagnitude   = [10];
prm.fieldMapWholePhase       = [11];

prm.overwriteFuncs  = 0; % 0 = create new func folder on each execution
prm.functionalAcqs  = [13 14 15 16 17 18 19 20];
prm.runs2analyze    = [1 2 3 4 5 6 7 8];
prm.CBLorder        = [1 2 3 4 5 6 7 8];
prm.covariatePath   = '/Volumes/Apollo/COVS';

prm.doSpikes   = 1;
prm.doDeskull  = 1;
prm.doFieldMap = 1;

prm.betF = '.5';
prm.betG = '0';

prm.fieldMapMagImage = 1;
prm.deltaTE = '2.46'; % this MUST be a string.

%% Run those functions

prm = makeParams(prm);
prm = data2moveAndRename(prm);
prm = prePreProcess(prm, prm.doSpikes, prm.doDeskull, prm.doFieldMap);