%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%         Import BrainStrom Protocol to BC-VARETA Format
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


% Authors
% - Ariosky Areces Gonzalez
% - Deirel Paz Linares
%
%   December 15, 2019


%% Preparing WorkSpace
clc;
close all;
clear all;
disp('-->> Starting process');
disp("=====================================================================");
restoredefaultpath;

%%
%------------ Preparing properties --------------------
% brainstorm('stop');
addpath(fullfile('app'));
addpath(fullfile('dataset_properties'));
addpath(fullfile('functions'));
addpath(fullfile('tools'));
addpath(fullfile('templates'));
addpath(genpath('plugins'));
% addpath(strcat('bst_lf_ppl',filesep,'guide'));
app_properties = jsondecode(fileread(fullfile('app','app_properties.json')));
 %% Printing data information
disp(strcat("-->> Name:",app_properties.generals.name));
disp(strcat("-->> Version:",app_properties.generals.version));
disp(strcat("-->> Version date:",app_properties.generals.version_date));
disp("=====================================================================");

if(isfile(fullfile("dataset_properties",app_properties.selected_data_format.file_name)))
    try
        selected_data_format = jsondecode(fileread(fullfile('dataset_properties',app_properties.selected_data_format.file_name)));
        app_properties.selected_data_format = selected_data_format;
    catch
        fprintf(2,"\n ->> Error: The selected_data_format file in config_protocols do not have a correct format \n");
        disp('-->> Process stoped!!!');
        return;
    end   
      
    %% ------------ Checking MatLab compatibility ----------------
    disp('-->> Checking installed matlab version');
    if(~app_check_matlab_version())
        return;
    end
    
    %% ------------  Checking updates --------------------------
    disp('-->> Checking project laster version');
    if(isequal(app_check_version,'updated'))
        return;
    end
    disp("=====================================================================");
    %% Process selected dataset and compute the leadfield subjects
    if(isfolder(app_properties.BCV_work_dir))
        selected_datastructure_process(app_properties);
    else
        fprintf(2,'\n ->> Error: The BC_VARETA_work_dir folder don''t exist\n');
        disp("");
        fprintf(2,char(app_properties.BCV_work_dir));
    end
    
    disp("=====================================================================");
    disp("-->> Process finished....");
else
    fprintf(2,strcat("\n ->> Error: The file ",app_properties.selected_data_format.file_name," do not exit \n"));
    disp("______________________________________________________________________________________________");
    disp("Please configure app_properties.selected_data_format.file_name element in app\\app_properties file. ")
end
