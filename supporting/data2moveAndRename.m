function prm = data2moveAndRename(prm)
%% FSL Pre-Analysis Stage 2 -- data2moveAndRename
%  This is Stage 2 in a 3-stage pre-analysis scripting pipeline.
%
%  Stage 2 moves the data from its raw location on Apollo and renames it
%  based on the parameters provided in Stage 1.
%
%  This script was written by Sam Weiller. For questions, please contact
%  sam.weiller@gmail.com
%
%  Created: 4/25/2014
%  Last Revision: 5/2/2014
%  Version Number: 0.71

startTime = GetSecs;
executionWarnings = 0;
%% Lets get started
if ~exist(prm.logFiles, 'dir')
    cmd = sprintf('mkdir -p %s', prm.logFiles);
    system(cmd);
end;

logFileName = sprintf('%s_%s_Stage2_log', prm.subject, prm.experiment);
FID = generateLogFile(logFileName, prm.logFiles);

textToLog = 'Log for Stage 2';
fprintf(FID, '%s\n', textToLog);
textToLog = 'Will attempt to copy, convert, and rename files.';
fprintf(FID, '%s\n\n', textToLog);

textToLog = 'Starting Stage 2 Pre-Analysis...';
fprintf(FID, '[M]%s:: %s\n', datestr(now, 'HHMMSSFFF'), textToLog);

dcm2niiCMD = '/Volumes/Zeus/FSLScripts/supporting/dcm2nii';

if ~exist(prm.rawLocation, 'dir')
    textToLog = sprintf('Raw data directory not found! Dir on file is: %s', prm.rawLocation);
    fprintf(FID, '!E!%s:: %s\n', datestr(now, 'HHMMSSFFF'), textToLog);
    error('STAGE 2 ABORTED! %s', textToLog);
end;

if prm.toProcess.anatomy
    if exist(sprintf('%s/anat/%s_anatomy.nii.gz', prm.destination, prm.subject), 'file')
        textToLog = 'Previous anatomy file found. Keeping both files.';
        fprintf(FID, '[M]%s:: %s\n', datestr(now, 'HHMMSSFFF'), textToLog);
        prm.procFilenames.anatomy = sprintf('%s_anatomy_%s.nii.gz', prm.subject, datestr(now, 'mmddyyHHMMSSFFF'));
    else
        textToLog = 'No previous anatomy file found.';
        fprintf(FID, '[M]%s:: %s\n', datestr(now, 'HHMMSSFFF'), textToLog);
        prm.procFilenames.anatomy = sprintf('%s_anatomy.nii.gz', prm.subject);
    end;
    
    cmd = sprintf('rm %s/t1*/*.nii.gz', prm.rawLocation);
    system(cmd);
    
    cmd = sprintf('%s %s/t1*', dcm2niiCMD, prm.rawLocation);
    cmdStatus = system(cmd);
    if cmdStatus == 1
        textToLog = sprintf('Command failed: %s', cmd);
        fprintf(FID, '!E!%s:: %s\n', datestr(now, 'HHMMSSFFF'), textToLog);
        error('STAGE 2 ABORTED! %s', textToLog);
    else
        textToLog = 'Anatomy has been converted.';
        fprintf(FID, '[M]%s:: %s\n', datestr(now, 'HHMMSSFFF'), textToLog);
    end;    
    
    cmd = sprintf('mv %s/t1*/co* %s/anat/%s', prm.rawLocation, prm.destination, prm.procFilenames.anatomy);
    cmdStatus = system(cmd);
    if cmdStatus == 1
        textToLog = sprintf('Command failed: %s', cmd);
        fprintf(FID, '!E!%s:: %s\n', datestr(now, 'HHMMSSFFF'), textToLog);
        error('STAGE 2 ABORTED! %s', textToLog);
    else
        textToLog = 'Anatomy has been moved to destination.';
        fprintf(FID, '[M]%s:: %s\n', datestr(now, 'HHMMSSFFF'), textToLog);
    end;
end;

if prm.toProcess.partial
    if exist(sprintf('%s/anat/%s_PartialTestSlice.nii.gz', prm.destination, prm.subject), 'file')
        textToLog = 'Previous Partial Test file found. Keeping both files.';
        fprintf(FID, '[M]%s:: %s\n', datestr(now, 'HHMMSSFFF'), textToLog);
        prm.procFilenames.partial = sprintf('%s_PartialTestSlice_%s.nii.gz', prm.subject, datestr(now, 'mmddyyHHMMSSFFF'));
    else
        textToLog = 'No previous partial test file found.';
        fprintf(FID, '[M]%s:: %s\n', datestr(now, 'HHMMSSFFF'), textToLog);
        prm.procFilenames.partial = sprintf('%s_PartialTestSlice.nii.gz', prm.subject);
    end;
    
    cmd = sprintf('rm %s/*_%d/*.nii.gz', prm.rawLocation, prm.partialTest);
    system(cmd);
    
    cmd = sprintf('%s %s/*_%d', dcm2niiCMD, prm.rawLocation, prm.partialTest);
    cmdStatus = system(cmd);
    if cmdStatus == 1
        textToLog = sprintf('Command failed: %s', cmd);
        fprintf(FID, '!E!%s:: %s\n', datestr(now, 'HHMMSSFFF'), textToLog);
        error('STAGE 2 ABORTED! %s', textToLog);
    else
        textToLog = 'Partial Test Slice has been converted.';
        fprintf(FID, '[M]%s:: %s\n', datestr(now, 'HHMMSSFFF'), textToLog);
    end;
    
    cmd = sprintf('mv %s/*_%d/*.nii.gz %s/anat/%s', prm.rawLocation, prm.partialTest, prm.destination, prm.procFilenames.partial);
    cmdStatus = system(cmd);
    if cmdStatus == 1
        textToLog = sprintf('Command failed: %s', cmd);
        fprintf(FID, '!E!%s:: %s\n', datestr(now, 'HHMMSSFFF'), textToLog);
        error('STAGE 2 ABORTED! %s', textToLog);
    else
        textToLog = 'Partial test slice has been moved to destination.';
        fprintf(FID, '[M]%s:: %s\n', datestr(now, 'HHMMSSFFF'), textToLog);
    end;
end;
    
if prm.toProcess.wholeBrain
    if exist(sprintf('%s/anat/%s_WholeBrainTest.nii.gz', prm.destination, prm.subject), 'file')
        textToLog = 'Previous whole brain test file found. Keeping both files.';
        fprintf(FID, '[M]%s:: %s\n', datestr(now, 'HHMMSSFFF'), textToLog);
        prm.procFilenames.wholeBrain = sprintf('%s_WholeBrainTest_%s.nii.gz', prm.subject, datestr(now, 'mmddyyHHMMSSFFF'));
    else
        textToLog = 'No previous whole brain test file found.';
        fprintf(FID, '[M]%s:: %s\n', datestr(now, 'HHMMSSFFF'), textToLog);
        prm.procFilenames.wholeBrain = sprintf('%s_WholeBrainTest.nii.gz', prm.subject);
    end;
    
    cmd = sprintf('rm %s/*_%d/*.nii.gz', prm.rawLocation, prm.wholeBrainTest);
    system(cmd);
    
    cmd = sprintf('%s %s/*_%d', dcm2niiCMD, prm.rawLocation, prm.wholeBrainTest);
    cmdStatus = system(cmd);
    if cmdStatus == 1
        textToLog = sprintf('Command failed: %s', cmd);
        fprintf(FID, '!E!%s:: %s\n', datestr(now, 'HHMMSSFFF'), textToLog);
        error('STAGE 2 ABORTED! %s', textToLog);
    else
        textToLog = 'Whole Brain Test Slice has been converted.';
        fprintf(FID, '[M]%s:: %s\n', datestr(now, 'HHMMSSFFF'), textToLog);
    end;
    
    cmd = sprintf('mv %s/*_%d/*.nii.gz %s/anat/%s', prm.rawLocation, prm.wholeBrainTest, prm.destination, prm.procFilenames.wholeBrain);
    cmdStatus = system(cmd);
    if cmdStatus == 1
        textToLog = sprintf('Command failed: %s', cmd);
        fprintf(FID, '!E!%s:: %s\n', datestr(now, 'HHMMSSFFF'), textToLog);
        error('STAGE 2 ABORTED! %s', textToLog);
    else
        textToLog = sprintf('Whole brain test slice has been moved to destination.');
        fprintf(FID, '[M]%s:: %s\n', datestr(now, 'HHMMSSFFF'), textToLog);
    end;
end;

if prm.toProcess.fieldMapPartialMagnitude
    %Filenames
    if (( exist(sprintf('%s/fieldmap/%s_FM_Partial_Magnitude1.nii.gz', prm.destination, prm.subject), 'file') || exist(sprintf('%s/fieldmap/%s_FM_Partial_Magnitude2.nii.gz', prm.destination, prm.subject), 'file') ))
        textToLog = 'Previous partial Magnitude image found (either 1 or 2). Will not overwrite.';
        fprintf(FID, '[M]%s:: %s\n', datestr(now, 'HHMMSSFFF'), textToLog);
        prm.procFilenames.fieldMapPartialMagnitude1 = sprintf('%s_FM_Partial_Magnitude1_%s.nii.gz', prm.subject, datestr(now, 'mmddyyHHMMSSFFF'));
        prm.procFilenames.fieldMapPartialMagnitude2 = sprintf('%s_FM_Partial_Magnitude2_%s.nii.gz', prm.subject, datestr(now, 'mmddyyHHMMSSFFF'));
    else
        textToLog = 'No previous partial magnitude images found.';
        fprintf(FID, '[M]%s:: %s\n', datestr(now, 'HHMMSSFFF'), textToLog);
        prm.procFilenames.fieldMapPartialMagnitude1 = sprintf('%s_FM_Partial_Magnitude1.nii.gz', prm.subject);
        prm.procFilenames.fieldMapPartialMagnitude2 = sprintf('%s_FM_Partial_Magnitude2.nii.gz', prm.subject);
    end;
    
    if exist(sprintf('%s/fieldmap/%s_FM_Partial_Phase.nii.gz', prm.destination, prm.subject), 'file')
        textToLog = 'Previous partial phase image found. Will not overwrite.';
        fprintf(FID, '[M]%s:: %s\n', datestr(now, 'HHMMSSFFF'), textToLog);
        prm.procFilenames.fieldMapPartialPhase = sprintf('%s_FM_Partial_Phase_%s.nii.gz', prm.subject, datestr(now, 'mmddyyHHMMSSFFF'));
    else
        textToLog = 'No previous partial phase image found.';
        fprintf(FID, '[M]%s:: %s\n', datestr(now, 'HHMMSSFFF'), textToLog);
        prm.procFilenames.fieldMapPartialPhase = sprintf('%s_FM_Partial_Phase.nii.gz', prm.subject);
    end;
    
    % Image1
    cmd = sprintf('rm %s/*_%d/*.nii.gz', prm.rawLocation, prm.fieldMapPartialMagnitude);
    system(cmd);
    
    cmd = sprintf('%s %s/*_%d', dcm2niiCMD, prm.rawLocation, prm.fieldMapPartialMagnitude);
    cmdStatus = system(cmd);
    if cmdStatus == 1
        textToLog = sprintf('Command failed: %s', cmd);
        fprintf(FID, '!E!%s:: %s\n', datestr(now, 'HHMMSSFFF'), textToLog);
        error('STAGE 2 ABORTED! %s', textToLog);
    else
        textToLog = 'Field Map Partial Magnitude 1 image has been converted.';
        fprintf(FID, '[M]%s:: %s\n', datestr(now, 'HHMMSSFFF'), textToLog);
    end;
    
    cmd = sprintf('mv %s/*_%d/*.nii.gz %s/fieldmap/%s', prm.rawLocation, prm.fieldMapPartialMagnitude, prm.destination, prm.procFilenames.fieldMapPartialMagnitude1);
    cmdStatus = system(cmd);
    if cmdStatus == 1
        textToLog = sprintf('Command failed: %s', cmd);
        fprintf(FID, '!E!%s:: %s\n', datestr(now, 'HHMMSSFFF'), textToLog);
        error('STAGE 2 ABORTED! %s', textToLog);
    else
        textToLog = 'Field Map Partial Magnitude 1 image has been moved to destination.';
        fprintf(FID, '[M]%s:: %s\n', datestr(now, 'HHMMSSFFF'), textToLog);
    end;
    
    % Image2
    cmd = sprintf('rm %s/*_%d/*.nii.gz', prm.rawLocation, prm.fieldMapPartialMagnitude);
    system(cmd);
    
    cmd = sprintf('%s %s/*_%d_2', dcm2niiCMD, prm.rawLocation, prm.fieldMapPartialMagnitude);
    cmdStatus = system(cmd);
    if cmdStatus == 1
        textToLog = sprintf('Command failed: %s', cmd);
        fprintf(FID, '!E!%s:: %s\n', datestr(now, 'HHMMSSFFF'), textToLog);
        error('STAGE 2 ABORTED! %s', textToLog);
    else
        textToLog = 'Field Map Partial Magnitude 2 image has been converted.';
        fprintf(FID, '[M]%s:: %s\n', datestr(now, 'HHMMSSFFF'), textToLog);
    end;
    
    cmd = sprintf('mv %s/*_%d_2/*.nii.gz %s/fieldmap/%s', prm.rawLocation, prm.fieldMapPartialMagnitude, prm.destination, prm.procFilenames.fieldMapPartialMagnitude2);
    cmdStatus = system(cmd);
    if cmdStatus == 1
        textToLog = sprintf('Command failed: %s', cmd);
        fprintf(FID, '!E!%s:: %s\n', datestr(now, 'HHMMSSFFF'), textToLog);
        error('STAGE 2 ABORTED! %s', textToLog);
    else
        textToLog = 'Field Map Partial Magnitude 2 image has been moved to destination.';
        fprintf(FID, '[M]%s:: %s\n', datestr(now, 'HHMMSSFFF'), textToLog);
    end;
end;

if prm.toProcess.fieldMapPartialPhase
    cmd = sprintf('rm %s/*_%d/*.nii.gz', prm.rawLocation, prm.fieldMapPartialPhase);
    system(cmd);
    
    cmd = sprintf('%s %s/*_%d_2', dcm2niiCMD, prm.rawLocation, prm.fieldMapPartialPhase);
    cmdStatus = system(cmd);
    if cmdStatus == 1
        textToLog = sprintf('Command failed: %s', cmd);
        fprintf(FID, '!E!%s:: %s\n', datestr(now, 'HHMMSSFFF'), textToLog);
        error('STAGE 2 ABORTED! %s', textToLog);
    else
        textToLog = 'Field Map Partial Phase image has been converted.';
        fprintf(FID, '[M]%s:: %s\n', datestr(now, 'HHMMSSFFF'), textToLog);
    end;
    
    cmd = sprintf('mv %s/*_%d_2/*.nii.gz %s/fieldmap/%s', prm.rawLocation, prm.fieldMapPartialPhase, prm.destination, prm.procFilenames.fieldMapPartialPhase);
    cmdStatus = system(cmd);
    if cmdStatus == 1
        textToLog = sprintf('Command failed: %s', cmd);
        fprintf(FID, '!E!%s:: %s\n', datestr(now, 'HHMMSSFFF'), textToLog);
        error('STAGE 2 ABORTED! %s', textToLog);
    else
        textToLog = 'Field Map Partial Phase image has been moved to destination.';
        fprintf(FID, '[M]%s:: %s\n', datestr(now, 'HHMMSSFFF'), textToLog);
    end;
end;

if prm.toProcess.fieldMapWholeMagnitude
    %filenames
    if (( exist(sprintf('%s/fieldmap/%s_FM_WholeBrain_Magnitude1.nii.gz', prm.destination, prm.subject), 'file') || exist(sprintf('%s/fieldmap/%s_FM_WholeBrain_Magnitude2.nii.gz', prm.destination, prm.subject), 'file') ))
        textToLog = 'Previous whole brain Magnitude image found (either 1 or 2). Will not overwrite.';
        fprintf(FID, '[M]%s:: %s\n', datestr(now, 'HHMMSSFFF'), textToLog);
        prm.procFilenames.fieldMapWholeMagnitude1 = sprintf('%s_FM_WholeBrain_Magnitude1_%s.nii.gz', prm.subject, datestr(now, 'mmddyyHHMMSSFFF'));
        prm.procFilenames.fieldMapWholeMagnitude2 = sprintf('%s_FM_WholeBrain_Magnitude2_%s.nii.gz', prm.subject, datestr(now, 'mmddyyHHMMSSFFF'));
    else
        textToLog = 'No previous Whole Brain magnitude images found.';
        fprintf(FID, '[M]%s:: %s\n', datestr(now, 'HHMMSSFFF'), textToLog);
        prm.procFilenames.fieldMapWholeMagnitude1 = sprintf('%s_FM_WholeBrain_Magnitude1.nii.gz', prm.subject);
        prm.procFilenames.fieldMapWholeMagnitude2 = sprintf('%s_FM_WholeBrain_Magnitude2.nii.gz', prm.subject);
    end;
    
    if exist(sprintf('%s/fieldmap/%s_FM_WholeBrain_Phase.nii.gz', prm.destination, prm.subject), 'file')
        textToLog = 'Previous whole brain phase image found. Will not overwrite.';
        fprintf(FID, '[M]%s:: %s\n', datestr(now, 'HHMMSSFFF'), textToLog);
        prm.procFilenames.fieldMapWholePhase = sprintf('%s_FM_WholeBrain_Phase_%s.nii.gz', prm.subject, datestr(now, 'mmddyyHHMMSSFFF'));
    else
        textToLog = 'No previous whole brain phase image found.';
        fprintf(FID, '[M]%s:: %s\n', datestr(now, 'HHMMSSFFF'), textToLog);
        prm.procFilenames.fieldMapWholePhase = sprintf('%s_FM_WholeBrain_Phase.nii.gz', prm.subject);
    end;
    
    % Image1
    cmd = sprintf('rm %s/*_%d/*.nii.gz', prm.rawLocation, prm.fieldMapWholeMagnitude);
    system(cmd);
    
    cmd = sprintf('%s %s/*_%d', dcm2niiCMD, prm.rawLocation, prm.fieldMapWholeMagnitude);
    cmdStatus = system(cmd);
    if cmdStatus == 1
        textToLog = sprintf('Command failed: %s', cmd);
        fprintf(FID, '!E!%s:: %s\n', datestr(now, 'HHMMSSFFF'), textToLog);
        error('STAGE 2 ABORTED! %s', textToLog);
    else
        textToLog = 'Field Map Whole Brain Magnitude 1 image has been converted.';
        fprintf(FID, '[M]%s:: %s\n', datestr(now, 'HHMMSSFFF'), textToLog);
    end;
    
    cmd = sprintf('mv %s/*_%d/*.nii.gz %s/fieldmap/%s', prm.rawLocation, prm.fieldMapWholeMagnitude, prm.destination, prm.procFilenames.fieldMapWholeMagnitude1);
    cmdStatus = system(cmd);
    if cmdStatus == 1
        textToLog = sprintf('Command failed: %s', cmd);
        fprintf(FID, '!E!%s:: %s\n', datestr(now, 'HHMMSSFFF'), textToLog);
        error('STAGE 2 ABORTED! %s', textToLog);
    else
        textToLog = 'Field Map Whole Brain Magnitude 1 image has been moved to destination.';
        fprintf(FID, '[M]%s:: %s\n', datestr(now, 'HHMMSSFFF'), textToLog);
    end;
    
    % Image2
    cmd = sprintf('rm %s/*_%d/*.nii.gz', prm.rawLocation, prm.fieldMapWholeMagnitude);
    system(cmd);
    
    cmd = sprintf('%s %s/*_%d_2', dcm2niiCMD, prm.rawLocation, prm.fieldMapWholeMagnitude);
    cmdStatus = system(cmd);
    if cmdStatus == 1
        textToLog = sprintf('Command failed: %s', cmd);
        fprintf(FID, '!E!%s:: %s\n', datestr(now, 'HHMMSSFFF'), textToLog);
        error('STAGE 2 ABORTED! %s', textToLog);
    else
        textToLog = 'Field Map Whole Brain Magnitude 2 image has been converted.';
        fprintf(FID, '[M]%s:: %s\n', datestr(now, 'HHMMSSFFF'), textToLog);
    end;
    
    cmd = sprintf('mv %s/*_%d_2/*.nii.gz %s/fieldmap/%s', prm.rawLocation, prm.fieldMapWholeMagnitude, prm.destination, prm.procFilenames.fieldMapWholeMagnitude2);
    cmdStatus = system(cmd);
    if cmdStatus == 1
        textToLog = sprintf('Command failed: %s', cmd);
        fprintf(FID, '!E!%s:: %s\n', datestr(now, 'HHMMSSFFF'), textToLog);
        error('STAGE 2 ABORTED! %s', textToLog);
    else
        textToLog = 'Field Map Whole Brain Magnitude 2 image has been moved to destination.';
        fprintf(FID, '[M]%s:: %s\n', datestr(now, 'HHMMSSFFF'), textToLog);
    end;
end;

if prm.toProcess.fieldMapWholePhase
    cmd = sprintf('rm %s/*_%d/*.nii.gz', prm.rawLocation, prm.fieldMapWholePhase);
    system(cmd);
    
    cmd = sprintf('%s %s/*_%d_2', dcm2niiCMD, prm.rawLocation, prm.fieldMapWholePhase);
    cmdStatus = system(cmd);
    if cmdStatus == 1
        textToLog = sprintf('Command failed: %s', cmd);
        fprintf(FID, '!E!%s:: %s\n', datestr(now, 'HHMMSSFFF'), textToLog);
        error('STAGE 2 ABORTED! %s', textToLog);
    else
        textToLog = 'Field Map Whole Brain Phase image has been converted.';
        fprintf(FID, '[M]%s:: %s\n', datestr(now, 'HHMMSSFFF'), textToLog);
    end;
    
    cmd = sprintf('mv %s/*_%d_2/*.nii.gz %s/fieldmap/%s', prm.rawLocation, prm.fieldMapWholePhase, prm.destination, prm.procFilenames.fieldMapWholePhase);
    cmdStatus = system(cmd);
    if cmdStatus == 1
        textToLog = sprintf('Command failed: %s', cmd);
        fprintf(FID, '!E!%s:: %s\n', datestr(now, 'HHMMSSFFF'), textToLog);
        error('STAGE 2 ABORTED! %s', textToLog);
    else
        textToLog = 'Field Map Whole Brain Phase image has been moved to destination.';
        fprintf(FID, '[M]%s:: %s\n', datestr(now, 'HHMMSSFFF'), textToLog);
    end;
end;

if prm.toProcess.functionals
    rawLoc       = prm.rawLocation;
    covLoc       = prm.covariatePath;
    acqs2analyze = prm.functionalAcqs;
    runs2analyze = prm.runs2analyze;
    run2CBL      = prm.CBLorder;
    subject      = prm.subject;
    experiment   = prm.experiment;
    funcDest     = prm.funcDestination;
    PARwarnings1 = zeros(prm.toProcess.functionals, 1);
    PARwarnings2 = zeros(prm.toProcess.functionals, 1);
    PARwarnings3 = zeros(prm.toProcess.functionals, 1);
    
    parfor i = 1:prm.toProcess.functionals
        cmd = sprintf('rm %s/*_%d/*.nii.gz', rawLoc, acqs2analyze(i));
        system(cmd);
        
        cmd = sprintf('%s %s/*_%d', dcm2niiCMD, rawLoc, acqs2analyze(i));
        cmdStatus = system(cmd);
        if cmdStatus == 1
            textToLog = sprintf('Command failed: %s', cmd);
            PARtextToLog1{i} = sprintf('!W!%s:: %s\n', datestr(now, 'HHMMSSFFF'), textToLog);
            PARwarnings1(i) = PARwarnings1(i) + 1;
        else
            textToLog = sprintf('Functional Run %02d, Acquisition %d has been converted.', runs2analyze(i), acqs2analyze(i));
            PARtextToLog1{i} = sprintf('[M]%s:: %s\n', datestr(now, 'HHMMSSFFF'), textToLog);
        end;
        
        tempFilename = sprintf('%s_%s_Run%02d.nii.gz', subject, experiment, runs2analyze(i));
        if exist(sprintf('%s/Run%02d/%s', funcDest, runs2analyze(i), tempFilename), 'file')
            textToLog = sprintf('Previous nifti found for Run%02d. Keeping both files.', runs2analyze(i));
            PARtextToLog2{i} = sprintf('[M]%s:: %s\n', datestr(now, 'HHMMSSFFF'), textToLog);
            tempFilename = sprintf('%s_%s_Run%02d_%s.nii.gz', subject, experiment, runs2analyze(i), datestr(now, 'mmddyyHHMMSSFFF'));
        else
            textToLog = sprintf('No previous nifti found for Run%02d.', runs2analyze(i));
            PARtextToLog2{i} = sprintf('[M]%s:: %s\n', datestr(now, 'HHMMSSFFF'), textToLog);
        end;
        
        cmd = sprintf('mv %s/*_%d/*.nii.gz %s/Run%02d/%s', rawLoc, acqs2analyze(i), funcDest, runs2analyze(i), tempFilename);
        cmdStatus = system(cmd);
        if cmdStatus == 1
            textToLog = sprintf('Command failed: %s', cmd);
            PARtextToLog3{i} = sprintf('!W!%s:: %s\n', datestr(now, 'HHMMSSFFF'), textToLog);
            PARwarnings2(i) = PARwarnings2(i) + 1;
        else
            textToLog = sprintf('Functional Run %02d, Acquisition %d has been moved to destination.', runs2analyze(i), acqs2analyze(i));
            PARtextToLog3{i} = sprintf('[M]%s:: %s\n', datestr(now, 'HHMMSSFFF'), textToLog);
        end;
        
        %COVS
        if ~isempty(covLoc)
            cmd = sprintf('cp %s/%s_CBL%02d_Acq%02d_Cov*.txt %s/Run%02d/', covLoc, subject, run2CBL(i), acqs2analyze(i), funcDest, runs2analyze(i));

            cmdStatus = system(cmd);
            if cmdStatus == 1
                textToLog = sprintf('Covariates not moved. Command failed: %s', cmd);
                PARtextToLog4{i} = sprintf('!W!%s:: %s\n', datestr(now, 'HHMMSSFFF'), textToLog);
                PARwarnings2(i) = PARwarnings3(i) + 1;
            else
                textToLog = sprintf('Covariates for functional Run %02d have been moved to destination.', runs2analyze(i));
                PARtextToLog4{i} = sprintf('[M]%s:: %s\n', datestr(now, 'HHMMSSFFF'), textToLog);
            end;
        else
            textToLog = sprintf('No covariate path provided. You must manually move your COVs.');
            PARtextToLog4{i} = sprintf('!W!%s:: %s\n', datestr(now, 'HHMMSSFFF'), textToLog);
            PARwarnings2(i) = PARwarnings3(i) + 1;
        end;
    end;
    
    for i = 1:prm.toProcess.functionals
        fprintf(FID, '%s', PARtextToLog1{i});
        fprintf(FID, '%s', PARtextToLog2{i});
        fprintf(FID, '%s', PARtextToLog3{i});
        fprintf(FID, '%s', PARtextToLog4{i});
        
        if sum(PARwarnings1) > 0
            executionWarnings = executionWarnings + sum(PARwarnings1);
        end;
        
        if sum(PARwarnings2) > 0
            executionWarnings = executionWarnings + sum(PARwarnings2);
        end;
        
        if sum(PARwarnings3) > 0
            executionWarnings = executionWarnings + sum(PARwarnings3);
        end;
    end;
end;

%% Save it Out
try
    save(prm.matFile, 'prm');
catch
    fclose(FID);
    error('Something went wrong with saving... Likely NONE of the Stage 2 analysis was carried out. "Your next life, maybe. Who knows? That''s the way these things go. "')
end;

if executionWarnings == 1
    fprintf('There was %d warning generated during this Stage. Please check the log file for !W! lines.\n', executionWarnings);
elseif executionWarnings > 1
    fprintf('There were %d warnings generated during this Stage. Please check the log file for !W! lines.\n', executionWarnings);
end;

textToLog = 'Stage 2 is complete!';
fprintf(FID, '[M]%s:: %s\n', datestr(now, 'HHMMSSFFF'), textToLog);
textToLog = sprintf('Number of Warnings generated: %d', executionWarnings);
fprintf(FID, '!W!%s:: %s\n', datestr(now, 'HHMMSSFFF'), textToLog);
totalTime = GetSecs - startTime;
textToLog = sprintf('Stage 2 took %1.3f seconds (%1.3f minutes) to run.', totalTime, (totalTime/60));
fprintf(FID, '[I]%s:: %s\n', datestr(now, 'HHMMSSFFF'), textToLog);
textToLog = 'Trinity says: "The answer is out there, Neo, and it''s looking for you, and it will find you if you want it to."';
fprintf(FID, '[I]%s:: %s\n', datestr(now, 'HHMMSSFFF'), textToLog);
textToLog = 'Closing log file...';
fprintf(FID, '[M]%s:: %s\n', datestr(now, 'HHMMSSFFF'), textToLog);

fclose(FID);