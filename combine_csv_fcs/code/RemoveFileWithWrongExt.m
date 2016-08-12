function [list_fcs_file ] = RemoveFileWithWrongExt( list_fcs_file )
%remove the uncessary files ==> identified extension: not a number
% 
filename_ext=cellfun(@(x) {x(end-3:end)},list_fcs_file.name);

ix=ismember(filename_ext,{'.BEK';'.bak';'.cfg';'.csv';'.tmp';'.txt';'.typ';'.xls';'ash~';'bash';'inV4';'orig';'tore'});
list_fcs_file(ix==1,:)=[];

ix=regexp(list_fcs_file.name,'external');
ix=arrayfun(@(x) length(x{:}),ix);
list_fcs_file(ix>0,:)=[];

ix=regexp(list_fcs_file.name,'core');
ix=arrayfun(@(x) length(x{:}),ix);
list_fcs_file(ix>0,:)=[];

ix=regexp(list_fcs_file.name,'Backup');
ix=arrayfun(@(x) length(x{:}),ix);
list_fcs_file(ix>0,:)=[];

end

