function [ list_fcs_file] = ExtractInfoFromPathName(list_fcs_file )
%UNTITLED2 Summary of this function goes here
%   Detailed explanation goes here

% extract the filename
new_array_temp = cellfun(@(x) strsplit(x, '/'), list_fcs_file.name, 'UniformOutput', false);
list_fcs_file.filename = cellfun(@(x) x{end}, new_array_temp, 'UniformOutput', false);
clear new_array_temp;

%  extract date and seq from filename
new_array_temp = cellfun(@(x) strsplit(x, '.'), list_fcs_file.filename , 'UniformOutput', false);

list_fcs_file.Seq = cellfun(@(x) x{end}, new_array_temp, 'UniformOutput', false);
list_fcs_file.Seq=cellfun(@(x) str2num(x),list_fcs_file.Seq);

list_fcs_file.date = cellfun(@(x) x{2}, new_array_temp, 'UniformOutput', false);
list_fcs_file.time = cellfun(@(x) x{3}, new_array_temp, 'UniformOutput', false);

list_fcs_file.datetime=strcat(list_fcs_file.date,list_fcs_file.time );
list_fcs_file.datetime=datenum(list_fcs_file.datetime,'yyyymmddHHMMSS');
list_fcs_file(:,{'date','time'})=[];
clear new_array_temp
%}
end

