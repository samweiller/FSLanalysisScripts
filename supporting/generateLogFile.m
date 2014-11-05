function [FID, logFilename] = generateLogFile(file, location)


% Create logfile stamped with current date and time
dateStamp = datestr(now, 'mmddyyyy');
timeStamp = datestr(now, 'HHMMSS');
filename = sprintf('%s_%s_%s.txt', file, dateStamp, timeStamp);

% in case of duplicate files, appends ms precision of creation time
if exist(sprintf('%s/%s', location, filename), 'file')
    filename = sprintf('%s_%s.txt', filename(1:end-4), datestr(now, 'FFF'));
end;

% open the file
logFilename = fullfile(location, filename);
FID = fopen(logFilename, 'w');

if FID < 0
    error('Cannot open file');
end

filePreamble = sprintf('Log Created %s', datestr(now, 'mm/dd/yyyy, HH:MM:SS'));
fprintf(FID, '%s\n', filePreamble);