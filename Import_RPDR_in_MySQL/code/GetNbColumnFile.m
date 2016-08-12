function [ numCols  ] = GetNbColumnFile(path_data,filename)
% return the number of columns in text file
delimiter = '|';
fid = fopen([path_data,filename.name],'rt');
tLines = fgets(fid);
numCols = numel(strfind(tLines,delimiter)) + 1;
fclose(fid);
end