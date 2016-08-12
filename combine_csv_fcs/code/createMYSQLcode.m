function code = createMYSQLcode(tableName,path_data,path_read_code)
%Create code to generate MYSQL table and load the data

filename=strcat(path_data,'*','.csv');
filename=dir(filename);

if ~isempty(filename)
    
    %Table.tx contains code to create mysql table
    F1=fileread(strcat(path_read_code,tableName,'Table.txt'));
   
    %Loadb and Loadb_old: contians code to upload data into table
    F2='';
    for f=1:length(filename)%if directory contains files from multiple queries, need to upload each query
        FLoad=fileread(strcat(path_read_code,tableName,'Loadb.txt'));
        F2=[F2,'SELECT '' File uploaded: ',filename(f).name,''' ; '];
        F2=[F2,'LOAD DATA LOCAL INFILE ''',path_data,filename(f).name,FLoad];
    end
    F3=fileread(strcat(path_read_code,tableName,'Modify.txt'));
    code=strcat(F1,F2,F3);
else
    code ='';
end

end