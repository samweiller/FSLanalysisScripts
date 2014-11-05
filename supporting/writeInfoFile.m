function writeInfoFile(prm)

if exist(sprintf('%s', prm.infoFile), 'file')
    prm.infoFile = sprintf('%s_%s.txt', prm.infoFile(1:end-4), datestr(now, 'FFF'));
end;

logFilename = fullfile(prm.infoFile);
FID = fopen(logFilename, 'w');

if FID < 0
    error('Cannot open info file');
end

fprintf(FID, 'PARAMETER FILE\n');
fprintf(FID, '%s\n\n', datestr(now, 'mm/dd/yyyy, HH:MM:SS'));
fprintf(FID, 'Project:\t%s\n', prm.projectName);
fprintf(FID, 'Subject:\t%s\n', prm.subject);
fprintf(FID, 'Experiment:\t%s\n', prm.experiment);
fprintf(FID, 'Subject Type:\t%s\n', prm.subType);
fprintf(FID, 'Analyzed By:\t%s\n', prm.expInitials);
fprintf(FID, 'Data Location:\t%s\n', prm.destination);
fprintf(FID, 'Params File:\t%s\n\n', prm.matFile);
fprintf(FID, 'ACQUISITION INFO\n');
fprintf(FID, 'Anatomical:\t\t%d\n', prm.anatomicalAcq);
fprintf(FID, 'Partial Test:\t\t%d\n', prm.partialTest);
fprintf(FID, 'Whole Brain Test:\t%d\n', prm.wholeBrainTest);
fprintf(FID, 'GRE Partial Mag:\t%d\n', prm.fieldMapPartialMagnitude);
fprintf(FID, 'GRE Partial Phase:\t%d\n', prm.fieldMapPartialPhase);
fprintf(FID, 'GRE Whole Brain Mag:\t%d\n', prm.fieldMapWholeMagnitude);
fprintf(FID, 'GRE Whole Brain Phase\t%d\n', prm.fieldMapWholePhase);
fprintf(FID, 'Functionals:\n%g \n', prm.functionalAcqs);
fprintf(FID, 'Functional Runs:\n%g \n', prm.runs2analyze);

fclose(FID);


