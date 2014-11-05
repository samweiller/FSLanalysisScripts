function prm = featMaker %(prm)
%% FSL Analysis -- Stage 4
%  Analysis stage 4 (featmaker) takes in an nth run FSF file and
%  generalizes it for all specified runs.

%% INPUT SECTION
project     = 'SCM';
subject     = 'SCM01';
experiment  = 'FOSS';
location    = '/Volumes/Zeus';

prm = loadParamsFile(project, subject, experiment, location);

prm.FEAT.sub2change      = prm.subject; % DO NOT CHANGE
prm.FEAT.run2change      = 1;
prm.FEAT.currentFEATname = '1stLevel';

%% Lets get started
startTime = GetSecs;
executionWarnings = 0;

if ~exist(prm.logFiles, 'dir')
    cmd = sprintf('mkdir -p %s', prm.logFiles);
    system(cmd);
end;

FSLpath = '/usr/local/fsl/bin';
featCMD = sprintf('%s/feat', FSLpath);

logFileName = sprintf('%s_%s_Stage4_log', prm.subject, prm.experiment);
FID = generateLogFile(logFileName, prm.logFiles);

textToLog = 'Log for Stage 4';
fprintf(FID, '%s\n', textToLog);
textToLog = 'Will attempt to copy, convert, and rename files.';
fprintf(FID, '%s\n\n', textToLog);

textToLog = 'Starting Stage 4 Analysis...';
fprintf(FID, '[M]%s:: %s\n', datestr(now, 'HHMMSSFFF'), textToLog);

%% Create the SEED
cmd = sprintf('echo %s/Run%02d/FIO*.fsf', prm.funcDestination, prm.FEAT.run2change);
[~, cmdOut] = system(cmd);

if cmdOut(end-5) == '*'
    textToLog = sprintf('No FIO fsf found. Command failed: %s', cmd);
    fprintf(FID, '!E!%s:: %s\n', datestr(now, 'HHMMSSFFF'), textToLog);
    error('STAGE 4 ABORTED! %s', textToLog);
else
    textToLog = 'FIO fsf found.';
    fprintf(FID, '[M]%s:: %s\n', datestr(now, 'HHMMSSFFF'), textToLog);
end;

pathLength = size(prm.funcDestination, 2) + 12; % 12 = /Run0X/FIO_ + 1
fileIntroLength  = size(sprintf('%s_%s_Run%02d_', prm.subject, prm.experiment, prm.FEAT.run2change), 2);

FEATidentity = cmdOut((pathLength+fileIntroLength):end);
textToLog = fprintf('FIO identity is %s.', FEATidentity);
fprintf(FID, '[M]%s:: %s\n', datestr(now, 'HHMMSSFFF'), textToLog);

inputFEAT = sprintf('%s/Run%02d/FIO*.fsf', prm.funcDestination, prm.FEAT.run2change);
sedCMD = sprintf('sed -e "s|%s|XXXX|g" -e "s|Run%02d|YYYY|g" ', prm.FEAT.sub2change, prm.FEAT.run2change);
SEEDname = sprintf('%s/SEED_%s', prm.funcDestination, FEATidentity(1:end-1));

cmd = sprintf('%s < %s > %s', sedCMD, inputFEAT, SEEDname);
cmdStatus = system(cmd);
if cmdStatus == 1
    textToLog = sprintf('Command failed: %s', cmd);
    fprintf(FID, '!E!%s:: %s\n', datestr(now, 'HHMMSSFFF'), textToLog);
    error('STAGE 4 ABORTED! %s', textToLog);
else
    textToLog = 'SEED fsf created from FIO fsf.';
    fprintf(FID, '[M]%s:: %s\n', datestr(now, 'HHMMSSFFF'), textToLog);
end;

cmd = sprintf('mv %s/Run%02d/FIO*.fsf %s/Run%02d/xFIO_%s.fsf', prm.funcDestination, prm.FEAT.run2change, prm.funcDestination, prm.FEAT.run2change, FEATidentity);
cmdStatus = system(cmd);
if cmdStatus == 1
    textToLog = sprintf('Command failed: %s', cmd);
    fprintf(FID, '!W!%s:: %s\n', datestr(now, 'HHMMSSFFF'), textToLog);
    executionWarnings = executionWarnings + 1;
else
    textToLog = 'Renamed FIO*.fsf to xFIO*_. fsf.';
    fprintf(FID, '[M]%s:: %s\n', datestr(now, 'HHMMSSFFF'), textToLog);
end;

%% Generalize
for i = 1:size(prm.runs2analyze, 2)
    sedCMD = sprintf('sed -e "s|XXXX|%s|g" -e "s|YYYY|Run%02d|g" ', prm.subject, prm.runs2analyze(i));
    outFEAT{i} = sprintf('%s/Run%02d/%s_%s_Run%02d_%s', prm.funcDestination, prm.runs2analyze(i), prm.subject, prm.experiment, prm.runs2analyze(i), FEATidentity);

    cmd = sprintf('%s < %s > %s', sedCMD, SEEDname, outFEAT{i});
    cmdStatus = system(cmd);

    if cmdStatus == 1
        textToLog = sprintf('Command failed: %s', cmd);
        fprintf(FID, '!E!%s:: %s\n', datestr(now, 'HHMMSSFFF'), textToLog);
        error('STAGE 4 ABORTED! %s', textToLog);
    else
        textToLog = sprintf('Created FEAT %s', outFEAT{i});
        fprintf(FID, '[M]%s:: %s\n', datestr(now, 'HHMMSSFFF'), textToLog);
    end;
end;

%% Run The Feats
runs2analyze = prm.runs2analyze;
PARwarnings = zeros(size(runs2analyze, 2),1);

parfor i = 1:size(runs2analyze, 2)
    featStart = GetSecs;
    fprintf('Running FEAT for Run %02d', runs2analyze(i));
    
    cmd = sprintf('%s %s', featCMD, outFEAT{i});
    cmdStatus = system(cmd);
    if cmdStatus == 1
        textToLog = sprintf('Command failed: %s', cmd);
        PARtextToLog{i} = sprintf('!W!%s:: %s\n', datestr(now, 'HHMMSSFFF'), textToLog);
        PARwarnings(i) = 1;
    else
        featTime = GetSecs - featStart;
        textToLog = sprintf('FEAT for Run %02d is complete. Elapsed Time: %1.2f seconds (%1.3f minutes).', runs2analyze(i), featTime, featTime/60);
        PARtextToLog{i} = sprintf('[M]%s:: %s\n', datestr(now, 'HHMMSSFFF'), textToLog);
    end;
end;

for i = 1:size(prm.runs2analyze, 2)
    fprintf(FID, '%s', PARtextToLog{i});
    
    if sum(PARwarnings) > 0
        executionWarnings = executionWarnings + sum(PARwarnings);
    end;
end;
    
%% Save it Out
try
    save(prm.matFile, 'prm');
catch
    fclose(FID);
    error('Something went wrong with saving... Likely NONE of the Stage 4 analysis was carried out. "Not like this..... Not like this."')
end;

if executionWarnings == 1
    fprintf('There was %d warning generated during this Stage. Please check the log file for !W! lines.\n', executionWarnings);
elseif executionWarnings > 1
    fprintf('There were %d warnings generated during this Stage. Please check the log file for !W! lines.\n', executionWarnings);
end;

textToLog = 'Stage 4 is complete!';
fprintf(FID, '[M]%s:: %s\n', datestr(now, 'HHMMSSFFF'), textToLog);
textToLog = sprintf('Number of Warnings generated: %d', executionWarnings);
fprintf(FID, '!W!%s:: %s\n', datestr(now, 'HHMMSSFFF'), textToLog);
totalTime = GetSecs - startTime;
textToLog = sprintf('Stage 4 took %1.3f seconds (%1.3f minutes) to run.', totalTime, (totalTime/60));
fprintf(FID, '[I]%s:: %s\n', datestr(now, 'HHMMSSFFF'), textToLog);
textToLog = 'Agent Smith says: "Never send a human to do a machine''s job."';
fprintf(FID, '[I]%s:: %s\n', datestr(now, 'HHMMSSFFF'), textToLog);
textToLog = 'Closing log file...';
fprintf(FID, '[M]%s:: %s\n', datestr(now, 'HHMMSSFFF'), textToLog);

fclose(FID);