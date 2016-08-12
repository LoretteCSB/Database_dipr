%% Abbot Sapphire: ADD THE PATH TO THE CSV FILES:


% THIS FILE CREATE A MYSQL DATABASE ON THE LOCAL SERVER which include all
% the csv files


% initial: 1 matlab mapfile, many csv files and fcs in many directories
% final: 1 files containing all the information

% Ia) create database containing all the csv files
% Ib) import this database in matlab and modify the date
%    (put it in Matlab fromat andignore hour:min:sec)

% IIa) Create a list of all the fcs filenames + path
% IIb) from the filename extract the date and seq and remove duplicates

% III a) Join the 2 lists in Matlab
% III b)  Updtae MYSQL
% DATABASE NAME IS: dbname
% THE SKELETON OF THE MYSQL CODE FOR EACH TABLE IS SAVED IN THE DIRECTORY path_read_code
% THE FILES TO UPLOAD ARE SAVED IN THE DIRECTORY SPECIFIED by: path_csv_files

%

%%
%% IMPORTANT: NEED TO CONNECT TO CSB SERVER BEFORE RUNNING THE SCRIPT

% % I automatically connect to the server at login
% alternativally I guess I could connect to the server from Matlab
% smb://rfa01.research.partners.org/MGH-CSB
% http://www.mathworks.com/help/datafeed/about-data-servers-and-data-service-providers.html
%%
clear
%% Path to the directory containing the rpdr data and the skeleton for the mysql code
dbname='Sapphire';
dbtablename='LogSapphire';
path_read_code='/Users/Lorette/Documents/MATLAB/database/mysql_fcs/Inputs/';
path_csv_files='/Volumes/MGH-CSB/higgins/data/sapphire/DataLogExtracts-42318az96/'; %name of the directory containing all the directories I want to include
path_fcs_dir  ='/Volumes/MGH-CSB/higgins/data/sapphire/';
path_save_outputs='/Users/Lorette/Documents/MATLAB/database/mysql_fcs/Result/';
map_file='/Users/Lorette/Documents/MATLAB/database/mysql_fcs/Inputs/tCBCAbbottAll20160105b.mat';% I modified variable name in original John File


addpath('/Users/Lorette/Documents/MATLAB/fileexchange')
load('/Users/Lorette/Documents/MATLAB/database/global/mdp.mat')
%% --------------------------------- DATABASE WITH CSV FILES ------------------------------
%%
% Ia) create database containing all the csv files

% CHECK IF I NEED TO CREATE THE DATABASE

conn = database('','root', mdp,'Vendor','MySQL','Server', 'localhost');


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

% createMYSQLcode: create table structure / load data / modify data

Code_DB=['USE ',dbname,';','SET max_error_count =50; '];
Code_Abbott= createMYSQLcode(dbtablename,path_csv_files,path_read_code);%write code for Dem in directory specify by pathcode
fileID = fopen([path_read_code,'Sapphire.sql'],'w');
Code=strcat(Code_DB,Code_Abbott);
fprintf(fileID,Code);
fclose(fileID);

% Execute code in terminal
exec_Terminal=['! /usr/local/mysql/bin/mysql --user root -p ',dbname,' -e "SOURCE ',path_read_code,'Sapphire.sql','"']
eval(exec_Terminal)
clear Code* fileID
%result=runsqlscript(conn,'myfile.sql')
%}
%% I b) Import csv data in Matlab and modify the database 
% import 
conn = database(dbname,'root', mdp,'Vendor','MySQL','Server', 'localhost');
ping(conn) %To check the connection:
sqlquery=['SELECT id,SpecID, Asptime,Seq,WBC FROM LogSapphire ;'];
curs = exec(conn,sqlquery)
curs = fetch(curs);
d=curs.Data;
close(curs); close(conn); clear conn curs sqlquery;

% remove rows with unvalid SpecID
% d(ismember(d.SpecID,{'AutoBkgd','Invalid','','no id'}),:)=[];% AutoBkg 3239, Invalid 8, blank 723

% modify the date variable
dateMatlab=datenum(d.Asptime);
d.datetime=dateMatlab; %check none of the date is NaN

%d.dateMatlab=fix(dateMatlab);%round towards 0
clear dateMatlab;
save([path_save_outputs,datestr(date,'yyyymmdd'),'_csv_file',dbname],'d')


%% --------------------------------- EXTRACT PATH TO FCS FILES ------------------------------
%% IIa) get the list of fcs file + path
%
% this step takes time, and do not need to be updated every time
list_fcs_file=struct2table(rdir([path_fcs_dir,'**/**']));%252133
save([path_save_outputs,datestr(date,'yyyymmdd'),'_recursive_dir',dbname],'list_fcs_file')

n=height(list_fcs_file)
list_fcs_file(:,{'date','bytes','isdir','datenum'})=[];
list_fcs_file=unique(list_fcs_file);

[ list_fcs_file ]= RemoveFileWithWrongExt( list_fcs_file );
[ list_fcs_file ]= ExtractInfoFromPathName(list_fcs_file );
%{
%remove the uncessary files ==> extension: not a number
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

clear ix filename_ext
%}
%{
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
%remove row with duplicated filenames (a file can be save in 2 directories
list_fcs_file = sortrows(list_fcs_file,{'filename','name'},'ascend');
[c,ia,ic]=unique(list_fcs_file.filename);
list_fcs_file = list_fcs_file(ia,:);
clear ia ic c
save([path_save_outputs,datestr(date,'yyyymmdd'),'_path_fcs',dbname],'list_fcs_file')

%% --------------------------------- COMBINE CSV AND path to FCS ------------------------------
% combine d with list_fcs_file
[csv_fcs,id,il]=innerjoin(d,list_fcs_file,'LeftKeys',{'Seq','datetime'},'RightKeys',{'Seq','datetime'});

% some files (1173) do not match, because Asptime is written with a decimal for the second ;e.g. '2015-08-07 22:40:11.0' 
% ==> solution: round to the second both date
d_not_mapped=d(setdiff(1:height(d),id),:);
list_fcs_file_not_mapped=list_fcs_file(setdiff(1:height(list_fcs_file),il),:);
d_not_mapped.datetimef=datenum_round_off(d_not_mapped.datetime,'second');
list_fcs_file_not_mapped.datetimef=datenum_round_off(list_fcs_file_not_mapped.datetime,'second');

[csv_fcs2,id,il]=innerjoin(d_not_mapped,list_fcs_file_not_mapped,'LeftKeys',{'Seq','datetimef'},'RightKeys',{'Seq','datetimef'});
csv_fcs2(:,{'datetimef','datetime_list_fcs_file_not_mapped'})=[];
csv_fcs2.Properties.VariableNames{'datetime_d_not_mapped'}='datetime';
csv_fcs=[csv_fcs;csv_fcs2];
csv_fcs=unique(csv_fcs);


% still have 1173 csv rows without fcs including 201 files with 'AutoBkgd','Invalid','','no id'
% still have 875 fcs files not matched
% ==> I could match 413 files with minutes

d_not_mapped=d(setdiff(1:height(d_not_mapped),id),:);
list_fcs_file_not_mapped=list_fcs_file_not_mapped(setdiff(1:height(list_fcs_file_not_mapped),il),:);
d_not_mapped.datetimef=datenum_round_off(d_not_mapped.datetime,'minute');
list_fcs_file_not_mapped.datetimef=datenum_round_off(list_fcs_file_not_mapped.datetime,'minute');
[csv_fcs3,id,il]=innerjoin(d_not_mapped,list_fcs_file_not_mapped,'LeftKeys',{'Seq','datetimef'},'RightKeys',{'Seq','datetimef'});
csv_fcs3(:,{'datetimef','datetime_list_fcs_file_not_mapped'})=[];
csv_fcs3.Properties.VariableNames{'datetime_d_not_mapped'}='datetime';
csv_fcs=[csv_fcs;csv_fcs3];


d_not_mapped=d(setdiff(1:height(d_not_mapped),id),:);
list_fcs_file_not_mapped=list_fcs_file_not_mapped(setdiff(1:height(list_fcs_file_not_mapped),il),:);
dvec=datevec(d_not_mapped.datetime);dvec(:,6)=0;
d_not_mapped.datetimef=datetime(dvec);
dvec=datevec(list_fcs_file_not_mapped.datetime);dvec(:,6)=0;
list_fcs_file_not_mapped.datetimef=datetime(dvec);
[csv_fcs4,id,il]=innerjoin(d_not_mapped,list_fcs_file_not_mapped,'LeftKeys',{'Seq','datetimef'},'RightKeys',{'Seq','datetimef'});
csv_fcs4(:,{'datetimef','datetime_list_fcs_file_not_mapped'})=[];
csv_fcs4.Properties.VariableNames{'datetime_d_not_mapped'}='datetime';
csv_fcs=[csv_fcs;csv_fcs4];

% I do not match the other: more than 1 minutes + file not uploaded

clear csv_fcs2 csv_fcs3 csv_fcs4 d_not_mapped list_fcs_file_not_mapped id il
save([path_save_outputs,datestr(date,'yyyymmdd'),'_csv_fcs_path',dbname],'csv_fcs')

% %% Export results to mysql
conn = database(dbname,'root', mdp,'Vendor','MySQL','Server', 'localhost');
%export date
for i=1:height(d)%pour mettre a jour la date des fichiers csv (meme si il n'y pas de fichier fcs associe)
    sqlquery=sprintf('UPDATE %s SET datetimeMatlab = ''%s'' WHERE id = %s;',dbtablename,num2str(d.datetime(i)),num2str(d.id(i)));
    curs = exec(conn,sqlquery);
end
%export filename
for i=1:height(csv_fcs)
    sqlquery=sprintf('UPDATE %s SET pathfcs = ''%s'', datetimeMatlab = ''%s'' WHERE id = %s;',dbtablename,csv_fcs.name{i},num2str(csv_fcs.datetime(i)),num2str(csv_fcs.id(i)));
    curs = exec(conn,sqlquery);
end
close(curs);close(conn); clear conn curs sqlquery
%}

%% COMBINE csv_FCS file Map 
load(map_file)
% Accession number for mrn 
%container id = sContainerID (tube number)

% I may have several map file so I take the last one
%most_recent_list_fcs=struct2table(dir(path_save_outputs));
%regexp(most_recent_list_fcs.name,['_csv_file',dbname]);
%load([path_save_outputs,datestr(date,'yyyymmdd'),'_csv_file',dbname],'d')

%tCBC ==> sContainerID is not unique. To be unique need to be combined with the date
% In the imported csv a lot of row have an issue with sContainer:
% AutoBkgd, no id...'2012-06-13 22:37:57.0'
tCBC.datetime=datenum(tCBC.dDate);

%% first add mrn to database 
% I tried different strategies to merge the info and choose the last one 

list_invalid_specID={'AutoBkgd',''};
d(ismember(d.SpecID,list_invalid_specID),:)=[];

[csv_map,id,it]=innerjoin(d,tCBC,'LeftKeys','SpecID','RightKeys','sContainerID');
%list_specID=unique(csv_map.SpecID);
%d2=d(ismember(d.SpecID,list_specID),:);

conn = database(dbname,'root', mdp,'Vendor','MySQL','Server', 'localhost');
for i=1:height(csv_map)
    sqlquery=sprintf('UPDATE %s SET mrn = ''%s'' WHERE id = %s;',dbtablename,...
        num2str(csv_map.mrnID(i)),num2str(csv_map.id(i)));
    curs = exec(conn,sqlquery);
end
close(curs); close(conn); clear conn curs sqlquery

% at this stage all the mrn contained in tCBC are matched with a row in
% csv... but a lot of row in csv still do not have a mrn. 
% + 1 SpecID may be used for several test (sContainerID) 
%% update sAccession 
[csv_map2,id,it]=innerjoin(d,tCBC,'LeftKeys',{'SpecID','datetime'},'RightKeys',{'sContainerID','datetime'});
conn = database(dbname,'root', mdp,'Vendor','MySQL','Server', 'localhost');
for i=1:height(csv_map2)
    sqlquery=sprintf('UPDATE %s SET sAccessionID = ''%s'' WHERE id = %s;',...
             dbtablename,csv_map2.sAccession{i},num2str(csv_map2.id(i)));
    curs = exec(conn,sqlquery);
end
close(curs); close(conn); clear conn curs sqlquery

%look at samples not matched
tCBC_not_mapped=tCBC(setdiff(1:height(tCBC),it),:);
d_not_mapped=d(setdiff(1:height(d),id),:);%0 sample

%some samples are not matching the date, maybe because date is slightly
%different==> I could match with rounded date
tCBC_not_mapped.datetimef=datenum_round_off(tCBC_not_mapped.datetime,'minute');
d_not_mapped.datetimef=datenum_round_off(d_not_mapped.datetime,'minute');

[csv_map3,id,it]=innerjoin(d_not_mapped,tCBC_not_mapped,'LeftKeys',{'SpecID','datetimef'},'RightKeys',{'sContainerID','datetimef'});
%[csv_map,id,it]=innerjoin(d_not_mapped,tCBC_not_mapped,'LeftKeys',{'SpecID'},'RightKeys',{'sContainerID'});
% ==> 799 row matched based on SpecId only / this row are a perfect match
% ==> I get 403 of these point if I rounf the data to the minute
conn = database(dbname,'root', mdp,'Vendor','MySQL','Server', 'localhost');
for i=1:height(csv_map3)
    sqlquery=sprintf('UPDATE %s SET sAccessionID = ''%s'' WHERE id = %s;',...
        dbtablename,csv_map3.sAccession{i},num2str(csv_map3.id(i)));
    curs = exec(conn,sqlquery);
end




close(curs); close(conn); clear conn curs sqlquery


save([path_save_outputs,datestr(date,'yyyymmdd'),'_map_csv_path_fcs',dbname],'csv_map*')
clear ia ic c csv_map2
