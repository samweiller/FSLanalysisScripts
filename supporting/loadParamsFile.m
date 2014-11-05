function prm = loadParamsFile(project, subject, experiment, location)
cmd = sprintf('ls %s/%s/logs/%s_%s*.mat | awk ''{print $1}''', location, project, subject, experiment);
[xxx mats] = system(cmd);
splitFiles = strsplit(mats, '\n');
paramFile = splitFiles{end-1};
load(paramFile);