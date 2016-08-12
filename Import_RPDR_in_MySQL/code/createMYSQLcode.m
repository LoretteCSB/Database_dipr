function code = createMYSQLcode(tableName,path_data,path_read_code)
%Create code to generate MYSQL table and load the data 

filename=strcat(path_data,'*',tableName,'.txt');
filename=dir(filename);

if ~isempty(filename)
    
    %Table.tx contains code to create mysql table
    F1=fileread(strcat(path_read_code,tableName,'Table.txt'));
   
    
    %Loadb and Loadb_old: contians code to upload data into table
    F2=''; 
    
    for f=1:length(filename)%if directory contains files from multiple queries, need to upload each query
     
        FLoad=fileread(strcat(path_read_code,tableName,'Loadb.txt'));
        if(strcmp(tableName,'Mrn'))%structure of table Enc changed: old version didn't contain the field "length of stay")
            numCols=GetNbColumnFile(path_data,filename(f));
            if(numCols==8)
                FLoad=fileread(strcat(path_read_code,tableName,'Loadb_old.txt'));
            end
        end
        
        if(strcmp(tableName,'Enc'))%structure of table Enc changed: old version didn't contain the field "length of stay")
            numCols=GetNbColumnFile(path_data,filename(f));
            if(numCols==30)
                FLoad=fileread(strcat(path_read_code,tableName,'Loadb_old.txt'));
            end
        end
         F2=[F2,'SELECT '' File uploaded: ',filename(f).name,''' ; '];
         F2=[F2,'LOAD DATA LOCAL INFILE ''',path_data,filename(f).name,FLoad];
    end
    
    %modify.txt: contains code to modify date format, add foreign key...
    F3=fileread(strcat(path_read_code,tableName,'Modify.txt'));
    
    code=strcat(F1,F2,F3);
    
else
    code ='';
end

end