%% THIS FILE CREATE A MYSQL DATABASE ON THE LOCAL SERVER
% DATABASE NAME IS: dbname
% THE SKELETON OF THE MYSQL CODE FOR EACH TABLE IS SAVED IN THE DIRECTORY path_read_code
% THE RPDR FILES (.txt) TO UPLOAD ARE SAVED IN THE DIRECTORY SPECIFIED by: path_data


clear

%% Path to the directory containing the rpdr data and the skeleton for the mysql code
path_read_code='/Users/Lorette/Documents/MATLAB/database/mysql_rpdr/Inputs/';

%dbname='Alloimmu_MGH'; path_data='/Volumes/MGH-CSB/Lorette/data_rpdr/Alloimmu/MGH/Merge/';
%dbname='Alloimmu_Brig';path_data='/Volumes/MGH-CSB/Lorette/data_rpdr/Alloimmu/screen_Brigham/';
dbname='healthy';

%dbname='MDS';
%dbname='renal_artery_stenosis';
%dbname='polycythemia';
%dbname='hemoglobinuria';%
%dbname='aplastic_anemia';
%dbname='renal_artery_stenosis';
%dbname='aplastic_anemia';
%dbname='splenectomy';
%dbname='pregnancy'
%path_data=['/Users/Lorette/Documents/POSTDOC/rpdr_data/RDW/',dbname,'/'];
%dbname='splenomegaly';
%dbname='Splenectomy';

dbname='Sapphire_fcs_map';

path_data=['/Volumes/MGH-CSB/Lorette/data_rpdr/',dbname,'/'];
addpath('/Users/Lorette/Documents/MATLAB/fileexchange')
load('/Users/Lorette/Documents/MATLAB/database/global/mdp_dipr.mat')

conn = database('','ln925',mdp ,'Vendor','MySQL','Server', 'mysql2.dipr.partners.org');

 %conn = database('','root',mdp,'Vendor','MySQL','Server', 'localhost');



ping(conn) %To check the connection:
sqlquery=['SHOW DATABASES ;'];
curs = exec(conn,sqlquery)
curs = fetch(curs);
dat=curs.Data;%2015b - for 2015a use curs.data
if ~max(strcmp(dbname,dat.SCHEMA_NAME))
    sqlquery=['CREATE DATABASE ', dbname,';'];
    curs = exec(conn,sqlquery)
end
close(curs);close(conn);clear conn curs dat sqlquery


%% IF I WANT TO CREATE A DB CONTAINING DATA FROM SEVERAL RPDR REQUEST :
%{
%path_data='/Users/Lorette/Documents/POSTDOC/rpdr_data/alloimmu/MGH/'
%path_data='/Volumes/MGH-CSB/Lorette/data_rpdr/Alloimmu/screen_Brigham/'

path_data='/Volumes/MGH-CSB/Lorette/data_rpdr/Sapphire_fcs_map/'
pathDirs=path_data; %name of the directory containing all the directories I want to include
newDir=[pathDirs,'Merge/'];%create a directory "Merge" in
mergeDirectories(pathDirs,newDir)
%
%%
%dbname='Alloimmu_MGH';
%path_data='/Users/Lorette/Documents/POSTDOC/rpdr_data/alloimmu/MGH/Merge/';

%}
%% CHECK IF I NEED TO CREATE THE DATABASE
%path_data='/Volumes/MGH-CSB/Lorette/data_rpdr/Alloimmu/screen_Brigham/Merge/'
path_data=strcat('/Volumes/MGH-CSB/Lorette/data_rpdr/',dbname,'/Merge/');
conn = database('','ln925',mdp ,'Vendor','MySQL','Server', 'mysql2.dipr.partners.org');

%conn = database('','root', 'Lorette1!','Vendor','MySQL','Server', 'localhost');
ping(conn) %To check the connection:

cursor = exec(conn,['SHOW DATABASES ;'])
cursor = fetch(cursor);
dat=cursor.Data;
if ~max(strcmp(dbname,dat.SCHEMA_NAME))
    cursor = exec(conn,['CREATE DATABASE ', dbname,';'])
end
close(cursor)
close(conn)

%% CREATE CODE FOR EACH TABLE and SAVE IT INTO A .sql FILE
% createMYSQLcode: create table structure / load data / modify data (format date, foreign key, remove duplicates for dia and enc)
%all the rpdr files to upload should be in the same directory defined by path_data

Code_DB=['USE ',dbname,';','SET max_error_count =50;'];

Code_Mrn= createMYSQLcode('Mrn',path_data,path_read_code);%write code for Dem in directory specify by pathcode
Code_Dem = createMYSQLcode('Dem',path_data,path_read_code);%write code for Dem in directory specify by pathcode
Code_Dia = createMYSQLcode('Dia',path_data,path_read_code);%write code for Dem in directory specify by pathcode
Code_Enc= createMYSQLcode('Enc',path_data,path_read_code);%write code for Dem in directory specify by pathcode
Code_Lab= createMYSQLcode('Lab',path_data,path_read_code);%write code for Dem in directory specify by pathcode
Code_Med= createMYSQLcode('Med',path_data,path_read_code);%write code for Dem in directory specify by pathcode
Code_Mee= createMYSQLcode('Mee',path_data,path_read_code);%write code for Dem in directory specify by pathcode
Code_Proc= createMYSQLcode('Prc',path_data,path_read_code);%write code for Dem in directory specify by pathcode
Code_Trn= createMYSQLcode('Trn',path_data,path_read_code);%write code for Dem in directory specify by pathcode
Code_Phy= createMYSQLcode('Phy',path_data,path_read_code);%write code for Dem in directory specify by pathcode
Code=strcat(Code_DB,Code_Mrn,Code_Dem,Code_Dia,Code_Enc,Code_Lab,Code_Med,Code_Mee,Code_Proc,Code_Trn,Code_Phy);

fileID = fopen([path_data,'myfile.sql'],'w');
fprintf(fileID,Code);
fclose(fileID);

% if future version, I may add the following check to avoid issues with foreign key:
% SELECT empi FROM Dem WHERE empi NOT IN (SELECT empi FROM Mrn);
% DELETE FROM Dem WHERE empi NOT IN (SELECT empi FROM Mrn);


%% Execute code in terminal
%exec_Terminal=['! /usr/local/mysql/bin/mysql --user root -p ',dbname,' -e "SOURCE ',path_data,'myfile.sql','"']
exec_Terminal=['! /usr/local/mysql/bin/mysql --host mysql2.dipr.partners.org --user ln925 -p ',dbname,' -e "SOURCE ',path_data,'myfile.sql','"']

eval(exec_Terminal)
%result=runsqlscript(conn,'myfile.sql')

%{
%% create a backup and save it on csb server
exec_Terminal=['! mysqldump -u root -p ',dbname,' > /Volumes/MGH-CSB/Lorette/Mysql_backup/',dbname,'.sql'];
eval(exec_Terminal)
%}

