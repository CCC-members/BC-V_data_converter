%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%         Import BrainStrom Protocol to BC-VARETA Format
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


% Authors
% - Ariosky Areces Gonzalez
% - Deirel Paz Linares
%
%    December 15, 2019


%% Preparing WorkSpace
clc;
close all;
clear all;
disp('-->> Starting process');
restoredefaultpath;

%%
%------------ Preparing properties --------------------
% brainstorm('stop');
addpath(fullfile('app'));
%addpath(fullfile('external'));
addpath(fullfile('functions'));
addpath(fullfile('tools'));
% addpath(strcat('bst_lf_ppl',filesep,'guide'));
%app_properties = jsondecode(fileread(strcat('properties',filesep,'app_properties.json')));
app_properties = jsondecode(fileread(strcat('app',filesep,'app_properties.json')));
app_protocols = jsondecode(fileread(strcat('app',filesep,'app_data_formats.json')));
selected_data_structure = app_protocols.(strcat('x',app_properties.selected_data_format.value));
app_properties.selected_data_format = selected_data_structure;
%% Printing data information
disp(strcat("-->> Name:",app_properties.generals.name));
disp(strcat("-->> Version:",app_properties.generals.version));
disp(strcat("-->> Version date:",app_properties.generals.version_date));
disp("=======================================================");

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

 %% Process selected dataset and compute the leadfield subjects
 selected_datastructure_process(app_properties);
 
 
    