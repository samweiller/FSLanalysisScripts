function prm = makeParams(prm)
%% FSL Pre-Analysis Stage 1 -- makeParams
%  This is Stage 1 in a 3-stage pre-analysis scripting pipeline.
%
%  Stage 1 defines all of the necessary parameters for the remaining
%  stages. The data you include in this file will also determine which 
%  parts of the analysis are carried out & where the files will be located.
%
%  This script was written by Sam Weiller. For questions, please contact
%  sam.weiller@gmail.com
%
%  Created: 4/24/2014
%  Last Revision: 5/2/2014
%  Version Number: 0.62

%% Create Param Files & Intial Folder Hierarchy
startTime = GetSecs;
% File name should have NO extension or date stamp. The function will take 
% care of that.
if ~exist(prm.logFiles, 'dir')
    cmd = sprintf('mkdir -p %s', prm.logFiles);
    system(cmd);
end;

executionWarnings = 0;
            
logFileName = sprintf('%s_%s_Stage1_log', prm.subject, prm.experiment);
FID = generateLogFile(logFileName, prm.logFiles);

textToLog = 'Log for Stage 1';
fprintf(FID, '%s\n', textToLog);
textToLog = 'Will attempt to create param file, info file, and folder hierarchy.';
fprintf(FID, '%s\n\n', textToLog);

textToLog = 'Starting Stage 1 Pre-Analysis...';
fprintf(FID, '[M]%s:: %s\n', datestr(now, 'HHMMSSFFF'), textToLog);

textToLog = 'Reading parameters.';
fprintf(FID, '[M]%s:: %s\n', datestr(now, 'HHMMSSFFF'), textToLog);

textToLog = sprintf('Experiment to Analyze: %s', prm.experiment);
fprintf(FID, '[I]%s:: %s\n', datestr(now, 'HHMMSSFFF'), textToLog);

% Complete raw Data Location
[~, fullLocation] = system(sprintf('ls -d %s', prm.rawLocation));
if strcmp(fullLocation, 'ls')
    textToLog = 'WARNING! your raw data directory does not exist. Maybe BITC has not synced yet?';
    fprintf(FID, '!W!%s:: %s\n', datestr(now, 'HHMMSSFFF'), textToLog);
    executionWarnings = executionWarnings + 1;
else
    prm.rawLocation = fullLocation(1:end-1);
end;
    
%% Anatomy
if isempty(prm.anatomicalAcq)
    textToLog = 'Anatomical not specified. Assuming already processed for now.';
    fprintf(FID, '[M]%s:: %s\n', datestr(now, 'HHMMSSFFF'), textToLog);
    toProcess.anatomy = 0;
else
    textToLog = sprintf('Anatomical acquisition is %d.', prm.anatomicalAcq);
    fprintf(FID, '[I]%s:: %s\n', datestr(now, 'HHMMSSFFF'), textToLog);
    toProcess.anatomy = 1;
end;

if isempty(prm.partialTest)
    textToLog = 'Partial Test Slice not specified. Assuming not being used or already processed.';
    fprintf(FID, '[M]%s:: %s\n', datestr(now, 'HHMMSSFFF'), textToLog);
    toProcess.partial = 0;
else
    textToLog = sprintf('Partial Test Slice acquisition is %d.', prm.partialTest);
    fprintf(FID, '[I]%s:: %s\n', datestr(now, 'HHMMSSFFF'), textToLog);
    toProcess.partial = 1;
end;

if isempty(prm.wholeBrainTest)
    textToLog = 'Whole Brain Test Slice not specified. Assuming not being used or already processed.';
    fprintf(FID, '[M]%s:: %s\n', datestr(now, 'HHMMSSFFF'), textToLog);
    toProcess.wholeBrain = 0;
else
    textToLog = sprintf('Whole Brain Test Slice acquisition is %d.', prm.wholeBrainTest);
    fprintf(FID, '[I]%s:: %s\n', datestr(now, 'HHMMSSFFF'), textToLog);
    toProcess.wholeBrain = 1;
end;

%% Field Maps
%  Partial
if isempty(prm.fieldMapPartialMagnitude)
    textToLog = 'Field map partial magnitude images not specified. Assuming not acquired.';
    fprintf(FID, '[M]%s:: %s\n', datestr(now, 'HHMMSSFFF'), textToLog);
    toProcess.fieldMapPartialMagnitude = 0;
else
    textToLog = sprintf('Field map partial magnitude image acquisitions are %d.', prm.fieldMapPartialMagnitude);
    fprintf(FID, '[I]%s:: %s\n', datestr(now, 'HHMMSSFFF'), textToLog);
    toProcess.fieldMapPartialMagnitude = 2;
end;

if isempty(prm.fieldMapPartialPhase)
    textToLog = 'Field map partial phase image not specified. Assuming not acquired.';
    fprintf(FID, '[M]%s:: %s\n', datestr(now, 'HHMMSSFFF'), textToLog);
    toProcess.fieldMapPartialPhase = 0;
else
    textToLog = sprintf('Field map partial phase image acquisition is %d.', prm.fieldMapPartialPhase);
    fprintf(FID, '[I]%s:: %s\n', datestr(now, 'HHMMSSFFF'), textToLog);
    toProcess.fieldMapPartialPhase = size(prm.fieldMapPartialPhase, 2);
end;

%  Whole
if isempty(prm.fieldMapWholeMagnitude)
    textToLog = 'Field map whole magnitude images not specified. Assuming not acquired.';
    fprintf(FID, '[M]%s:: %s\n', datestr(now, 'HHMMSSFFF'), textToLog);
    toProcess.fieldMapWholeMagnitude = 0;
else
    textToLog = sprintf('Field map whole magnitude image acquisitions are %d.', prm.fieldMapWholeMagnitude);
    fprintf(FID, '[I]%s:: %s\n', datestr(now, 'HHMMSSFFF'), textToLog);
    toProcess.fieldMapWholeMagnitude = 2;
end;

if isempty(prm.fieldMapWholePhase)
    textToLog = 'Field map whole phase image not specified. Assuming not acquired.';
    fprintf(FID, '[M]%s:: %s\n', datestr(now, 'HHMMSSFFF'), textToLog);
    toProcess.fieldMapWholePhase = 0;
else
    textToLog = sprintf('Field map whole phase image acquisition is %d.', prm.fieldMapWholePhase);
    fprintf(FID, '[I]%s:: %s\n', datestr(now, 'HHMMSSFFF'), textToLog);
    toProcess.fieldMapWholePhase = size(prm.fieldMapWholePhase, 2);
end;

%% Functionals
if isempty(prm.functionalAcqs)
    textToLog = 'No functional acquisitions specified! Assuming anatomical analysis only.';
    fprintf(FID, '[M]%s:: %s\n', datestr(now, 'HHMMSSFFF'), textToLog);
    toProcess.functionals = 0;
else
    if isempty(prm.runs2analyze)
        textToLog = 'Functional acquisitions provided without specifying run numbers! Aborting analysis.';
        fprintf(FID, '!E!%s:: %s\n', datestr(now, 'HHMMSSFFF'), textToLog);
        error('STAGE 1 ABORTED! %s', textToLog);
    else
        if size(prm.functionalAcqs, 2) == size(prm.runs2analyze, 2)
            for i = 1:size(prm.functionalAcqs, 2)
                textToLog = sprintf('Run %d is Acquisition %d', prm.runs2analyze(i), prm.functionalAcqs(i));
                fprintf(FID, '[I]%s:: %s\n', datestr(now, 'HHMMSSFFF'), textToLog);
            end;
            toProcess.functionals = size(prm.functionalAcqs, 2);
        else
            textToLog = 'Number of runs and functional acquisitions do not match! Aborting analysis.';
            fprintf(FID, '!E!%s:: %s\n', datestr(now, 'HHMMSSFFF'), textToLog);
            error('STAGE 1 ABORTED! %s', textToLog);
        end;
    end;
end;

%% Determine folders to create
if toProcess.anatomy
    if exist(sprintf('%s/anat', prm.destination), 'dir')
        textToLog = 'Previous anatomy folder found. Any new anatomy files will be placed here with appended filenames.';
        fprintf(FID, '[M]%s:: %s\n', datestr(now, 'HHMMSSFFF'), textToLog);
    else
        textToLog = 'No previous anatomy folder found. Creating now.';
        fprintf(FID, '[M]%s:: %s\n', datestr(now, 'HHMMSSFFF'), textToLog);
        cmd = sprintf('mkdir -p %s/anat', prm.destination);
        system(cmd);
    end;
end;

if (( toProcess.fieldMapPartialMagnitude || toProcess.fieldMapPartialPhase || toProcess.fieldMapWholeMagnitude || toProcess.fieldMapWholePhase )) 
    if exist(sprintf('%s/fieldmap', prm.destination), 'dir');
        textToLog = 'Previous fieldmap folder found. Any new FM files will be placed here with appended filenames.';
        fprintf(FID, '[M]%s:: %s\n', datestr(now, 'HHMMSSFFF'), textToLog);
    else %no fieldmap folder
        textToLog = 'No previous fieldmap folder found. Creating now.';
        fprintf(FID, '[M]%s:: %s\n', datestr(now, 'HHMMSSFFF'), textToLog);
        cmd = sprintf('mkdir -p %s/fieldmap', prm.destination);
        system(cmd);
    end;
end;

if toProcess.functionals
    if exist(sprintf('%s/%s_func', prm.destination, prm.experiment), 'dir')
        if prm.overwriteFuncs == 1
            textToLog = 'Previous func folder found for this experiment. Will overwrite contents.';
            fprintf(FID, '[M]%s:: %s\n', datestr(now, 'HHMMSSFFF'), textToLog);
            prm.funcDestination = sprintf('%s/%s_func', prm.destination, prm.experiment);
        else
            textToLog = 'Previous func folder found for this experiment. Will create new folder.';
            fprintf(FID, '[M]%s:: %s\n', datestr(now, 'HHMMSSFFF'), textToLog);
            prm.funcDestination = sprintf('%s/%s_func_%s', prm.destination, prm.experiment, datestr(now, 'mmddyyHHMMSSFFF'));
            cmd = sprintf('mkdir -p %s', prm.funcDestination);
            system(cmd);
        end;
    else
        textToLog = 'No previous func folder found for this experiment. Will create now.';
        fprintf(FID, '[M]%s:: %s\n', datestr(now, 'HHMMSSFFF'), textToLog);
        prm.funcDestination = sprintf('%s/%s_func', prm.destination, prm.experiment);
        cmd = sprintf('mkdir -p %s', prm.funcDestination);
        system(cmd);
    end;
    
    % Run folders
    for i = 1:toProcess.functionals
        if exist(sprintf('%s/Run%02d', prm.funcDestination, prm.runs2analyze(i)), 'dir')
            textToLog = sprintf('Folder found for Run%02d.', prm.runs2analyze(i));
            fprintf(FID, '[M]%s:: %s\n', datestr(now, 'HHMMSSFFF'), textToLog);
        else
            textToLog = sprintf('No folder found for Run%02d. Creating now.', prm.runs2analyze(i));
            fprintf(FID, '[M]%s:: %s\n', datestr(now, 'HHMMSSFFF'), textToLog);
            cmd = sprintf('mkdir -p %s/Run%02d', prm.funcDestination, prm.runs2analyze(i));
            system(cmd);
        end;
    end;
end;

%% Save it out
prm.matFile = sprintf('%s/%s_%s_%s_prms.mat', prm.logFiles, prm.subject, prm.experiment, datestr(now, 'mmddyyHHMMSSFFF'));
prm.toProcess = toProcess;
textToLog = 'Writing params to info file.';
fprintf(FID, '[M]%s:: %s\n', datestr(now, 'HHMMSSFFF'), textToLog);

writeInfoFile(prm);

try
    save(prm.matFile, 'prm');
catch
    fclose(FID);
    error('Something went wrong with saving... Likely NONE of your analysis was carried out. Everyone falls on their first jump.')
end;

if executionWarnings == 1
    fprintf('There was %d warning generated during this Stage. Please check the log file for !W! lines.\n', executionWarnings);
elseif executionWarnings > 1
    fprintf('There were %d warnings generated during this Stage. Please check the log file for !W! lines.\n', executionWarnings);
end;

textToLog = 'Stage 1 is complete!';
fprintf(FID, '[M]%s:: %s\n', datestr(now, 'HHMMSSFFF'), textToLog);
textToLog = sprintf('Number of Warnings generated: %d', executionWarnings);
fprintf(FID, '!W!%s:: %s\n', datestr(now, 'HHMMSSFFF'), textToLog);
totalTime = GetSecs - startTime;
textToLog = sprintf('Stage 1 took %1.3f seconds (%1.3f minutes) to run.', totalTime, (totalTime/60));
fprintf(FID, '[I]%s:: %s\n', datestr(now, 'HHMMSSFFF'), textToLog);
textToLog = 'Morpheus says: Throughout human history, we have been dependent on machines to survive. Fate, it seems, is not without a sense of irony.';
fprintf(FID, '[I]%s:: %s\n', datestr(now, 'HHMMSSFFF'), textToLog);
textToLog = 'Closing log file...';
fprintf(FID, '[M]%s:: %s\n', datestr(now, 'HHMMSSFFF'), textToLog);
fclose(FID);