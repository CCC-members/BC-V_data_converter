function [] = clean_eeg_by_user_labels(selected_data_format)
root_path = selected_data_format.BCV_work_dir;
subjects = dir(fullfile(root_path,'**','subject.mat'));
if(~isempty(subjects))
    for i=1:length(subjects)
        subject_file_info = subjects(i);
        subject = struct;
        load(fullfile(subject_file_info.folder,subject_file_info.name));
        output_subject_dir = subject_file_info.folder;      
                
        %% Finding the labels file
        labels_file = fullfile(selected_data_format.labels_file_path);
        if(isfile(labels_file))
            labels = jsondecode(fileread(labels_file));
            if(isequal(subject_info.modality,'EEG'))
                disp ("-->> Loading EEG file and EEG information");
                load(fullfile(subject_file_info.folder,subject_info.eeg_dir));
                load(fullfile(subject_file_info.folder,subject_info.eeg_info_dir));
                disp ("-->> Checking EEG file and EEG information");
                [data,hdr]  = remove_eeg_channels_by_labels(labels,data,hdr);                
                disp ("-->> Loading Leadfield and  Channel files");
                load(fullfile(subject_file_info.folder,subject_info.leadfield_dir(1).path));
                load(fullfile(subject_file_info.folder,subject_info.scalp_dir));
                disp ("-->> Removing Channels by preprocessed MEG");
                label = replace(hdr.label,'REF','');
                [Cdata,Ke] = remove_channels_and_leadfield_from_layout(label,Cdata,Ke);
                disp ("-->> Sorting Channels and LeadField by preprocessed MEG");
                [Cdata_s,Ke] = sort_channels_and_leadfield_by_labels(label,Cdata_r,Ke);
                HeadModels(h).Ke = Ke;
%                 save(fullfile(output_subject_dir,'eeg','eeg.mat'),'data');
%                 save(fullfile(output_subject_dir,'eeg_info','eeg_info.mat'),'hdr');
            else
                
            end
            disp ("-->> Saving scalp file");
            save(fullfile(output_subject_dir,'scalp','scalp.mat'),'Cdata','Sh');
            disp ("-->> Saving subject file");
            save(fullfile(output_subject_dir,'subject.mat'),'subject_info');
        else
            fprintf(2,strcat('\nBC-V-->> Error: The system can not find the follow file: \n'));
            disp(labels_file);            
            fprintf(2,strcat('BC-V-->> Error: Check the processed_data field configuration.\n'));
        end
    end
else
    fprintf(2,strcat('\nBC-V-->> Error: The folder structure: \n'));
    disp(root_path);
    fprintf(2,strcat('BC-V-->> Error: Do not contain any subject information file.\n'));
    disp("Please verify the configuration of the input data and start the process again.");
    return;
end
end

