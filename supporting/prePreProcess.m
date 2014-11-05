function prm = prePreProcess(prm, doSpikes, doDeskull, doFieldMap)
%% FSL Pre-Analysis Stage 3 -- prePreProcess
%  This is Stage 3 in a 3-stage analysis scripting pipeline.
%
%  Stage 3 performs the basic precursors to PreProcessing, including
%  deskulling, calculating motion spikes, and generating field maps.
%
%  This script was written by Sam Weiller. For questions, please contact
%  sam.weiller@gmail.com
%
%  Created: 4/28/2014
%  Last Revision: 5/2/2014
%  Version Number: 0.61

startTime = GetSecs;
%% Let's get started
howManySteps = doSpikes + doDeskull + doFieldMap;
if howManySteps == 0
    fprintf('No analyses specified. Quitting.\n');
    return;
end;

if ~exist(prm.logFiles, 'dir')
    cmd = sprintf('mkdir -p %s', prm.logFiles);
    system(cmd);
end;

logFileName = sprintf('%s_%s_Stage3_log', prm.subject, prm.experiment);
FID = generateLogFile(logFileName, prm.logFiles);

setenv('FSLOUTPUTTYPE', 'NIFTI_GZ');

FSLpath = '/usr/local/fsl/bin';
spikesCMD = sprintf('%s/fsl_motion_outliers', FSLpath);
betCMD    = sprintf('%s/bet', FSLpath);
prepFMCMD = sprintf('%s/fsl_prepare_fieldmap', FSLpath);

textToLog = 'Log for Stage 3';
fprintf(FID, '%s\n', textToLog);
textToLog = 'See below for plan.';
fprintf(FID, '%s\n\n', textToLog);

textToLog = 'Starting Stage 3 Pre-Analysis...';
fprintf(FID, '[M]%s:: %s\n', datestr(now, 'HHMMSSFFF'), textToLog);

textToLog = sprintf('Number of analysis steps: %d', howManySteps);
fprintf(FID, '[I]%s:: %s\n', datestr(now, 'HHMMSSFFF'), textToLog);

if doSpikes
    textToLog = 'Will attempt to calculate motion spikes.';
    fprintf(FID, '[I]%s:: %s\n', datestr(now, 'HHMMSSFFF'), textToLog);
end;

if doDeskull
    textToLog = 'Will attempt to deskull brains.';
    fprintf(FID, '[I]%s:: %s\n', datestr(now, 'HHMMSSFFF'), textToLog);
end;

if doFieldMap
    textToLog = 'Will attempt to generate field maps.';
    fprintf(FID, '[I]%s:: %s\n', datestr(now, 'HHMMSSFFF'), textToLog);
end;

executionWarnings = 0;
%% Spikes
if doSpikes
    runs2analyze = prm.runs2analyze;
    subject = prm.subject;
    experiment = prm.experiment;
    funcDestination = prm.funcDestination;
    PARwarnings = zeros(size(runs2analyze, 2),1);
    
    parfor i = 1:size(runs2analyze, 2)
        textToLog = sprintf('Calculating Spikes for Run %02d', runs2analyze(i));
        PARtextToLog{i} = sprintf('[M]%s:: %s\n', datestr(now, 'HHMMSSFFF'), textToLog);
        
        NIFTI = sprintf('%s_%s_Run%02d.nii.gz', subject, experiment, runs2analyze(i));
        cmd = sprintf('%s -i %s/Run%02d/%s -o %s/Run%02d/%s_spikes.txt --dummy=0', spikesCMD, funcDestination, runs2analyze(i), NIFTI, funcDestination, runs2analyze(i), NIFTI(1:end-7));
        cmdStatus = system(cmd);
        if cmdStatus == 1
            textToLog = sprintf('Command failed: %s', cmd);
            PARtextToLog{i} = sprintf('!W!%s:: %s\n', datestr(now, 'HHMMSSFFF'), textToLog);
            PARwarnings(i) = 1;
        end;
        
        spikeMat = dlmread(sprintf('%s/Run%02d/%s_spikes.txt', funcDestination, runs2analyze(i), NIFTI(1:end-7)));
        numSpikes  = size(spikeMat, 2);
        numVolumes = size(spikeMat, 1);
        textToLog = sprintf('Run %02d Spike Analysis: %d spikes out of %d volumes (%1.2f percent).', runs2analyze(i), numSpikes, numVolumes, (numSpikes/numVolumes)*100);
        PARtextToLog2{i} = sprintf('[M]%s:: %s\n', datestr(now, 'HHMMSSFFF'), textToLog);
        spikePercents(i) = numSpikes/numVolumes;
    end;
    
    for i = 1:size(runs2analyze, 2)
        fprintf(FID, '%s', PARtextToLog{i});
        fprintf(FID, '%s', PARtextToLog2{i});
        if spikePercents(i) > .1
            textToLog = sprintf('WARNING! Run %02d has greater than 10 percent spikes.', i);
            fprintf(FID, '!W!%s:: %s\n', datestr(now, 'HHMMSSFFF'), textToLog);
            executionWarnings = executionWarnings + 1;
        end;
        
        if sum(PARwarnings) > 0
            executionWarnings = executionWarnings + sum(PARwarnings);
        end;
    end;
end;

%% Deskulling
if doDeskull
    if prm.toProcess.anatomy
        if exist(sprintf('%s/anat/%s_anatomy_brain.nii.gz', prm.destination, prm.subject), 'file')
            textToLog = 'Previous deskulled anatomy file found. Keeping both files.';
            fprintf(FID, '[M]%s:: %s\n', datestr(now, 'HHMMSSFFF'), textToLog);
            prm.procFilenames.anatomyDS = sprintf('%s_anatomy_brain_%s.nii.gz', prm.subject, datestr(now, 'mmddyyHHMMSSFFF'));
        else
            textToLog = 'No previous deskulled anatomy file found.';
            fprintf(FID, '[M]%s:: %s\n', datestr(now, 'HHMMSSFFF'), textToLog);
            prm.procFilenames.anatomyDS = sprintf('%s_anatomy_brain.nii.gz', prm.subject);
        end;
        
        cmd = sprintf('%s %s/anat/%s %s/anat/%s -f %s -g %s', betCMD, prm.destination, prm.procFilenames.anatomy, prm.destination, prm.procFilenames.anatomyDS, prm.betF, prm.betG);
        cmdStatus = system(cmd);
        if cmdStatus == 1
            textToLog = sprintf('Command failed: %s', cmd);
            fprintf(FID, '!E!%s:: %s\n', datestr(now, 'HHMMSSFFF'), textToLog);
            error('STAGE 3 ABORTED! %s', textToLog);
        else
            textToLog = 'Anatomy has been deskulled.';
            fprintf(FID, '[M]%s:: %s\n', datestr(now, 'HHMMSSFFF'), textToLog);
        end;
        
        % MGZ
        cmd = 'export FREESURFER_HOME=/usr/local/freesurfer';
        system(cmd);
        cmd = 'source $FREESURFER_HOME/SetUpFreeSurfer.sh';
        system(cmd);
        if cmdStatus == 1
            textToLog = sprintf('Command failed: %s', cmd);
            fprintf(FID, '!W!%s:: %s\n', datestr(now, 'HHMMSSFFF'), textToLog);
            executionWarnings = executionWarnings + 1;
        else
            textToLog = 'Freesurfer initialized.';
            fprintf(FID, '[M]%s:: %s\n', datestr(now, 'HHMMSSFFF'), textToLog);
        end;
        
        tempDirLocation = system(sprintf('echo $SUBJECTS_DIR/%s/mri/orig', prm.subject));
        if exist(sprintf('%s', tempDirLocation), 'dir')
            textToLog = 'Previous mri/orig folder found. Files WILL be overwritten here.';
            fprintf(FID, '[M]%s:: %s\n', datestr(now, 'HHMMSSFFF'), textToLog);
        else
            textToLog = 'No previous mri/orig folder found. Creating now.';
            fprintf(FID, '[M]%s:: %s\n', datestr(now, 'HHMMSSFFF'), textToLog);
            cmd = sprintf('mkdir -p $SUBJECTS_DIR/%s/mri/orig', prm.subject);
            system(cmd);
            if cmdStatus == 1
                textToLog = sprintf('Command failed: %s', cmd);
                fprintf(FID, '!W!%s:: %s\n', datestr(now, 'HHMMSSFFF'), textToLog);
                executionWarnings = executionWarnings + 1;
            else
                textToLog = 'mri/orig directory created.';
                fprintf(FID, '[M]%s:: %s\n', datestr(now, 'HHMMSSFFF'), textToLog);
            end;
        end;
        
        tempDirLocation = system(sprintf('echo $SUBJECTS_DIR/%s/label', prm.subject));
        if exist(sprintf('%s', tempDirLocation), 'dir')
            textToLog = 'Previous label folder found. Files WILL be overwritten here.';
            fprintf(FID, '[M]%s:: %s\n', datestr(now, 'HHMMSSFFF'), textToLog);
        else
            textToLog = 'No previous label folder found. Creating now.';
            fprintf(FID, '[M]%s:: %s\n', datestr(now, 'HHMMSSFFF'), textToLog);
            cmd = sprintf('mkdir -p $SUBJECTS_DIR/%s/label', prm.subject);
            system(cmd);
            if cmdStatus == 1
                textToLog = sprintf('Command failed: %s', cmd);
                fprintf(FID, '!W!%s:: %s\n', datestr(now, 'HHMMSSFFF'), textToLog);
                executionWarnings = executionWarnings + 1;
            else
                textToLog = 'Label directory created,';
                fprintf(FID, '[M]%s:: %s\n', datestr(now, 'HHMMSSFFF'), textToLog);
            end;
        end;
        
        tempFileLocation = system(sprintf('echo $SUBJECTS_DIR/%s/mri/orig/anat.mgz', prm.subject));
        if exist(sprintf('%s', tempFileLocation), 'file')
            textToLog = 'Previous anat.mgz file found. WARNING: OVERWRITING.';
            fprintf(FID, '!W!%s:: %s\n', datestr(now, 'HHMMSSFFF'), textToLog);
            executionWarnings = executionWarnings + 1;
        else
            textToLog = 'No previous anat.mgz file found.';
            fprintf(FID, '[M]%s:: %s\n', datestr(now, 'HHMMSSFFF'), textToLog);
        end;
        
        cmd = sprintf('mri_convert %s/anat/%s $SUBJECTS_DIR/%s/mri/orig/anat.mgz', prm.destination, prm.procFilenames.anatomyDS, prm.subject);
        cmdStatus = system(cmd);
        if cmdStatus == 1
            textToLog = sprintf('Command failed: %s', cmd);
            fprintf(FID, '!W!%s:: %s\n', datestr(now, 'HHMMSSFFF'), textToLog);
            executionWarnings = executionWarnings + 1;
        else
            textToLog = 'MGZ file has been created and placed inside the Freesurfer directory.';
            fprintf(FID, '[M]%s:: %s\n', datestr(now, 'HHMMSSFFF'), textToLog);
        end;
    end;
    
    if prm.toProcess.partial
        if exist(sprintf('%s/anat/%s_PartialTestSlice_brain.nii.gz', prm.destination, prm.subject), 'file')
            textToLog = 'Previous deskulled partial test slice file found. Keeping both files.';
            fprintf(FID, '[M]%s:: %s\n', datestr(now, 'HHMMSSFFF'), textToLog);
            prm.procFilenames.partialDS = sprintf('%s_PartialTestSlice_brain_%s.nii.gz', prm.subject, datestr(now, 'mmddyyHHMMSSFFF'));
        else
            textToLog = 'No previous deskulled partial test slice file found.';
            fprintf(FID, '[M]%s:: %s\n', datestr(now, 'HHMMSSFFF'), textToLog);
            prm.procFilenames.partialDS = sprintf('%s_PartialTestSlice_brain.nii.gz', prm.subject);
        end;
        
        cmd = sprintf('%s %s/anat/%s %s/anat/%s -f %s -g %s', betCMD, prm.destination, prm.procFilenames.partial, prm.destination, prm.procFilenames.partialDS, prm.betF, prm.betG);
        cmdStatus = system(cmd);
        if cmdStatus == 1
            textToLog = sprintf('Command failed: %s', cmd);
            fprintf(FID, '!E!%s:: %s\n', datestr(now, 'HHMMSSFFF'), textToLog);
            error('STAGE 3 ABORTED! %s', textToLog);
        else
            textToLog = 'Partial test slice has been deskulled.';
            fprintf(FID, '[M]%s:: %s\n', datestr(now, 'HHMMSSFFF'), textToLog);
        end;
    end;
    
    if prm.toProcess.wholeBrain
        if exist(sprintf('%s/anat/%s_WholeBrainTest_brain.nii.gz', prm.destination, prm.subject), 'file')
            textToLog = 'Previous deskulled whole brain test slice file found. Keeping both files.';
            fprintf(FID, '[M]%s:: %s\n', datestr(now, 'HHMMSSFFF'), textToLog);
            prm.procFilenames.wholeBrainDS = sprintf('%s_WholeBrainTest_brain_%s.nii.gz', prm.subject, datestr(now, 'mmddyyHHMMSSFFF'));
        else
            textToLog = 'No previous deskulled whole brain test slice file found.';
            fprintf(FID, '[M]%s:: %s\n', datestr(now, 'HHMMSSFFF'), textToLog);
            prm.procFilenames.wholeBrainDS = sprintf('%s_WholeBrainTest_brain.nii.gz', prm.subject);
        end;
        
        cmd = sprintf('%s %s/anat/%s %s/anat/%s -f %s -g %s', betCMD, prm.destination, prm.procFilenames.wholeBrain, prm.destination, prm.procFilenames.wholeBrainDS, prm.betF, prm.betG);
        cmdStatus = system(cmd);
        if cmdStatus == 1
            textToLog = sprintf('Command failed: %s', cmd);
            fprintf(FID, '!E!%s:: %s\n', datestr(now, 'HHMMSSFFF'), textToLog);
            error('STAGE 3 ABORTED! %s', textToLog);
        else
            textToLog = 'Whole brain test slice has been deskulled.';
            fprintf(FID, '[M]%s:: %s\n', datestr(now, 'HHMMSSFFF'), textToLog);
        end;
    end;
    
    if prm.toProcess.fieldMapPartialMagnitude
        if exist(sprintf('%s/fieldmap/%s_FM_Partial_Magnitude1_brain.nii.gz', prm.destination, prm.subject), 'file')
            textToLog = 'Previous deskulled partial FM magnitude 1 image found. Keeping both files.';
            fprintf(FID, '[M]%s:: %s\n', datestr(now, 'HHMMSSFFF'), textToLog);
            prm.procFilenames.fieldMapPartialMagnitude1DS = sprintf('%s_FM_Partial_Magnitude1_brain_%s.nii.gz', prm.subject, datestr(now, 'mmddyyHHMMSSFFF'));
        else
            textToLog = 'No previous deskulled partial FM magnitude 1 image found.';
            fprintf(FID, '[M]%s:: %s\n', datestr(now, 'HHMMSSFFF'), textToLog);
            prm.procFilenames.fieldMapPartialMagnitude1DS = sprintf('%s_FM_Partial_Magnitude1_brain.nii.gz', prm.subject);
        end;
        
        cmd = sprintf('%s %s/fieldmap/%s %s/fieldmap/%s -f %s -g %s', betCMD, prm.destination, prm.procFilenames.fieldMapPartialMagnitude1, prm.destination, prm.procFilenames.fieldMapPartialMagnitude1DS, prm.betF, prm.betG);
        cmdStatus = system(cmd);
        if cmdStatus == 1
            textToLog = sprintf('Command failed: %s', cmd);
            fprintf(FID, '!E!%s:: %s\n', datestr(now, 'HHMMSSFFF'), textToLog);
            error('STAGE 3 ABORTED! %s', textToLog);
        else
            textToLog = 'Partial FM magnitude 1 image has been deskulled.';
            fprintf(FID, '[M]%s:: %s\n', datestr(now, 'HHMMSSFFF'), textToLog);
        end;
        
        if exist(sprintf('%s/fieldmap/%s_FM_Partial_Magnitude2_brain.nii.gz', prm.destination, prm.subject), 'file')
            textToLog = 'Previous deskulled partial FM magnitude 2 image found. Keeping both files.';
            fprintf(FID, '[M]%s:: %s\n', datestr(now, 'HHMMSSFFF'), textToLog);
            prm.procFilenames.fieldMapPartialMagnitude2DS = sprintf('%s_FM_Partial_Magnitude2_brain_%s.nii.gz', prm.subject, datestr(now, 'mmddyyHHMMSSFFF'));
        else
            textToLog = 'No previous deskulled partial FM magnitude 2 image found.';
            fprintf(FID, '[M]%s:: %s\n', datestr(now, 'HHMMSSFFF'), textToLog);
            prm.procFilenames.fieldMapPartialMagnitude2DS = sprintf('%s_FM_Partial_Magnitude2_brain.nii.gz', prm.subject);
        end;
        
        cmd = sprintf('%s %s/fieldmap/%s %s/fieldmap/%s -f %s -g %s', betCMD, prm.destination, prm.procFilenames.fieldMapPartialMagnitude2, prm.destination, prm.procFilenames.fieldMapPartialMagnitude2DS, prm.betF, prm.betG);
        cmdStatus = system(cmd);
        if cmdStatus == 1
            textToLog = sprintf('Command failed: %s', cmd);
            fprintf(FID, '!E!%s:: %s\n', datestr(now, 'HHMMSSFFF'), textToLog);
            error('STAGE 3 ABORTED! %s', textToLog);
        else
            textToLog = 'Partial FM magnitude 2 image has been deskulled.';
            fprintf(FID, '[M]%s:: %s\n', datestr(now, 'HHMMSSFFF'), textToLog);
        end;
    end;
    
    if prm.toProcess.fieldMapWholeMagnitude
        if exist(sprintf('%s/fieldmap/%s_FM_WholeBrain_Magnitude1_brain.nii.gz', prm.destination, prm.subject), 'file')
            textToLog = 'Previous deskulled whole brain FM magnitude 1 image found. Keeping both files.';
            fprintf(FID, '[M]%s:: %s\n', datestr(now, 'HHMMSSFFF'), textToLog);
            prm.procFilenames.fieldMapWholeMagnitude1DS = sprintf('%s_FM_WholeBrain_Magnitude1_brain_%s.nii.gz', prm.subject, datestr(now, 'mmddyyHHMMSSFFF'));
        else
            textToLog = 'No previous deskulled whole brain FM magnitude 1 image found.';
            fprintf(FID, '[M]%s:: %s\n', datestr(now, 'HHMMSSFFF'), textToLog);
            prm.procFilenames.fieldMapWholeMagnitude1DS = sprintf('%s_FM_WholeBrain_Magnitude1_brain.nii.gz', prm.subject);
        end;
        
        cmd = sprintf('%s %s/fieldmap/%s %s/fieldmap/%s -f %s -g %s', betCMD, prm.destination, prm.procFilenames.fieldMapWholeMagnitude1, prm.destination, prm.procFilenames.fieldMapWholeMagnitude1DS, prm.betF, prm.betG);
        cmdStatus = system(cmd);
        if cmdStatus == 1
            textToLog = sprintf('Command failed: %s', cmd);
            fprintf(FID, '!E!%s:: %s\n', datestr(now, 'HHMMSSFFF'), textToLog);
            error('STAGE 3 ABORTED! %s', textToLog);
        else
            textToLog = 'Whole brain FM magnitude 1 image has been deskulled.';
            fprintf(FID, '[M]%s:: %s\n', datestr(now, 'HHMMSSFFF'), textToLog);
        end;
        
        if exist(sprintf('%s/fieldmap/%s_FM_WholeBrain_Magnitude2_brain.nii.gz', prm.destination, prm.subject), 'file')
            textToLog = 'Previous deskulled whole brain FM magnitude 2 image found. Keeping both files.';
            fprintf(FID, '[M]%s:: %s\n', datestr(now, 'HHMMSSFFF'), textToLog);
            prm.procFilenames.fieldMapWholeMagnitude2DS = sprintf('%s_FM_WholeBrain_Magnitude2_brain_%s.nii.gz', prm.subject, datestr(now, 'mmddyyHHMMSSFFF'));
        else
            textToLog = 'No previous deskulled whole brain FM magnitude 2 image found.';
            fprintf(FID, '[M]%s:: %s\n', datestr(now, 'HHMMSSFFF'), textToLog);
            prm.procFilenames.fieldMapWholeMagnitude2DS = sprintf('%s_FM_WholeBrain_Magnitude2_brain.nii.gz', prm.subject);
        end;
        
        cmd = sprintf('%s %s/fieldmap/%s %s/fieldmap/%s -f %s -g %s', betCMD, prm.destination, prm.procFilenames.fieldMapWholeMagnitude2, prm.destination, prm.procFilenames.fieldMapWholeMagnitude2DS, prm.betF, prm.betG);
        cmdStatus = system(cmd);
        if cmdStatus == 1
            textToLog = sprintf('Command failed: %s', cmd);
            fprintf(FID, '!E!%s:: %s\n', datestr(now, 'HHMMSSFFF'), textToLog);
            error('STAGE 3 ABORTED! %s', textToLog);
        else
            textToLog = 'Whole brain FM magnitude 2 image has been deskulled.';
            fprintf(FID, '[M]%s:: %s\n', datestr(now, 'HHMMSSFFF'), textToLog);
        end;
    end;
end;

%% Field Map
if doFieldMap
    if prm.toProcess.fieldMapPartialMagnitude
        FMdest = sprintf('%s/fieldmap', prm.destination);
        switch prm.fieldMapMagImage
            case 1
                magnitudeImage = sprintf('%s/%s', FMdest, prm.procFilenames.fieldMapPartialMagnitude1DS);
            case 2
                magnitudeImage = sprintf('%s/%s', FMdest, prm.procFilenames.fieldMapPartialMagnitude2DS);
        end;
        
        if exist(sprintf('%s/fieldmap/%s_PartialFieldMap.nii.gz', prm.destination, prm.subject), 'file')
            textToLog = 'Previous partial Field Map found. Keeping both files.';
            fprintf(FID, '[M]%s:: %s\n', datestr(now, 'HHMMSSFFF'), textToLog);
            prm.procFilenames.partialFieldMap = sprintf('%s_PartialFieldMap_%s.nii.gz', prm.subject, datestr(now, 'mmddyyHHMMSSFFF'));
        else
            textToLog = 'No previous partial field map found.';
            fprintf(FID, '[M]%s:: %s\n', datestr(now, 'HHMMSSFFF'), textToLog);
            prm.procFilenames.partialFieldMap = sprintf('%s_PartialFieldMap.nii.gz', prm.subject);
        end;
        
        cmd = sprintf('%s SIEMENS %s/%s %s %s/%s %s', prepFMCMD, FMdest, prm.procFilenames.fieldMapPartialPhase, magnitudeImage, FMdest, prm.procFilenames.partialFieldMap, prm.deltaTE);
        cmdStatus = system(cmd);
        if cmdStatus == 1
            textToLog = sprintf('Command failed: %s', cmd);
            fprintf(FID, '!E!%s:: %s\n', datestr(now, 'HHMMSSFFF'), textToLog);
            error('STAGE 3 ABORTED! %s', textToLog);
        else
            textToLog = sprintf('Partial field map has been created.');
            fprintf(FID, '[M]%s:: %s\n', datestr(now, 'HHMMSSFFF'), textToLog);
        end;
    end;
    
    if prm.toProcess.fieldMapWholeMagnitude
        FMdest = sprintf('%s/fieldmap', prm.destination);
        switch prm.fieldMapMagImage
            case 1
                magnitudeImage = sprintf('%s/%s', FMdest, prm.procFilenames.fieldMapWholeMagnitude1DS);
            case 2
                magnitudeImage = sprintf('%s/%s', FMdest, prm.procFilenames.fieldMapWholeMagnitude2DS);
        end;
        
        if exist(sprintf('%s/fieldmap/%s_WholeBrainFieldMap.nii.gz', prm.destination, prm.subject), 'file')
            textToLog = 'Previous whole brain Field Map found. Keeping both files.';
            fprintf(FID, '[M]%s:: %s\n', datestr(now, 'HHMMSSFFF'), textToLog);
            prm.procFilenames.wholeBrainFieldMap = sprintf('%s_WholeBrainFieldMap_%s.nii.gz', prm.subject, datestr(now, 'mmddyyHHMMSSFFF'));
        else
            textToLog = 'No previous whole brain field map found.';
            fprintf(FID, '[M]%s:: %s\n', datestr(now, 'HHMMSSFFF'), textToLog);
            prm.procFilenames.wholeBrainFieldMap = sprintf('%s_WholeBrainFieldMap.nii.gz', prm.subject);
        end;
        
        cmd = sprintf('%s SIEMENS %s/%s %s %s/%s %s', prepFMCMD, FMdest, prm.procFilenames.fieldMapWholePhase, magnitudeImage, FMdest, prm.procFilenames.wholeBrainFieldMap, prm.deltaTE);
        cmdStatus = system(cmd);
        if cmdStatus == 1
            textToLog = sprintf('Command failed: %s', cmd);
            fprintf(FID, '!E!%s:: %s\n', datestr(now, 'HHMMSSFFF'), textToLog);
            error('STAGE 3 ABORTED! %s', textToLog);
        else
            textToLog = 'Whole Brain field map has been created.';
            fprintf(FID, '[M]%s:: %s\n', datestr(now, 'HHMMSSFFF'), textToLog);
        end;
    end;
end;

%% Save it Out
try
    save(prm.matFile, 'prm');
catch
    fclose(FID);
    error('Something went wrong with saving... Likely NONE of the Stage 3 analysis was carried out. "You think that''s air you''re breathing?"')
end;

if executionWarnings == 1
    fprintf('There was %d warning generated during this Stage. Please check the log file for !W! lines.\n', executionWarnings);
elseif executionWarnings > 1
    fprintf('There were %d warnings generated during this Stage. Please check the log file for !W! lines.\n', executionWarnings);
end;

textToLog = 'Stage 3 is complete!';
fprintf(FID, '[M]%s:: %s\n', datestr(now, 'HHMMSSFFF'), textToLog);
textToLog = sprintf('Number of Warnings generated: %d', executionWarnings);
fprintf(FID, '!W!%s:: %s\n', datestr(now, 'HHMMSSFFF'), textToLog);
totalTime = GetSecs - startTime;
textToLog = sprintf('Stage 3 took %1.3f seconds (%1.3f minutes) to run.', totalTime, (totalTime/60));
fprintf(FID, '[I]%s:: %s\n', datestr(now, 'HHMMSSFFF'), textToLog);
textToLog = 'Morpheus says: "Come on! Stop trying to hit me and hit me!"';
fprintf(FID, '[I]%s:: %s\n', datestr(now, 'HHMMSSFFF'), textToLog);
textToLog = 'Closing log file...';
fprintf(FID, '[M]%s:: %s\n', datestr(now, 'HHMMSSFFF'), textToLog);

fclose(FID);