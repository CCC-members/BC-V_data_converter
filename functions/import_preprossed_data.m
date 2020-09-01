function [] = import_preprossed_data(selected_data_format)
root_path = selected_data_format.BCV_work_dir;
subjects = dir(fullfile(root_path,'**','subject.mat'));
if(~isempty(subjects))
    for i=1:length(subjects)
        subject_file_info = subjects(i);
        subject = struct;
        load(fullfile(subject_file_info.folder,subject_file_info.name));
        output_subject_dir = subject_file_info.folder;      
        leadfield = load(fullfile(output_subject_dir,subject_info.leadfield_dir));
        scalp = load(fullfile(output_subject_dir,subject_info.scalp_dir));
        
        Ke = leadfield.Ke;
        Cdata = scalp.Cdata;
        Sh = scalp.Sh;
        
        %% Finding the preprocessed data
        filepath = strrep(selected_data_format.preprocessed_data.file_location,'SubID',subject_info.name);
        base_path =  strrep(selected_data_format.preprocessed_data.base_path,'SubID',subject_info.name);
        data_file = fullfile(base_path,filepath);
        if(isfile(data_file))
            if(isequal(subject_info.modality,'EEG'))
                disp ("-->> Genering data file");
                [hdr, data] = import_eeg_format(data_file,selected_data_format.preprocessed_data.format);
                labels = hdr.label;
                labels = strrep(labels,'REF','');
                disp ("-->> Removing Channels  by preprocessed EEG");
                [Cdata,Ke] = remove_channels_and_leadfield_from_layout(labels,Cdata,Ke);
                disp ("-->> Sorting Channels and LeadField by preprocessed EEG");
                [Cdata,Ke] = sort_channels_and_leadfield_by_labels(label,Cdata,Ke);
                subject_info.eeg_dir = fullfile('eeg','eeg.mat');
                subject_info.eeg_info_dir = fullfile('eeg','eeg_info.mat');
                disp ("-->> Saving eeg_info file");
                save(fullfile(output_subject_dir,'eeg','eeg_info.mat'),'hdr');
                disp ("-->> Saving eeg file");
                save(fullfile(output_subject_dir,'eeg','eeg.mat'),'data');
            else
                disp ("-->> Genering meg file");
                meg = load(data_file);
                hdr = meg.data.hdr;
                fsample = meg.data.fsample;
                trialinfo = meg.data.trialinfo;
                grad = meg.data.grad;
                time = meg.data.time;
                label = meg.data.label;
                cfg = meg.data.cfg;
                %                 labels = strrep(labels,'REF','');
                disp ("-->> Removing Channels  by preprocessed MEG");
                [Cdata,Ke] = remove_channels_and_leadfield_from_layout(label,Cdata,Ke);
                disp ("-->> Sorting Channels and LeadField by preprocessed MEG");
                [Cdata,Ke] = sort_channels_and_leadfield_by_labels(label,Cdata,Ke);
                
                data = [];
                for i=1: length(meg.data.trial)
                    disp (strcat("-->> Indexing trial #: ",string(i)));
                    trial = cell2mat(meg.data.trial(1,i));
                    data = [data trial];
                end
                subject_info.meg_dir = fullfile('meg','meg.mat');
                subject_info.meg_info_dir = fullfile('meg','meg_info.mat');
                disp ("-->> Saving meg_info file");
                save(strcat(output_subject_dir,filesep,'meg',filesep,'meg_info.mat'),'hdr','fsample','trialinfo','grad','time','label','cfg');
                disp ("-->> Saving meg file");
                save(strcat(output_subject_dir,filesep,'meg',filesep,'meg.mat'),'data');
            end
            disp ("-->> Saving scalp file");
            save(fullfile(output_subject_dir,'scalp','scalp.mat'),'Cdata','Sh');
            disp ("-->> Saving subject file");
            save(fullfile(output_subject_dir,'subject.mat'),'subject_info');
        else
            fprintf(2,strcat('\nBC-V-->> Error: The system can not find the follow file: \n'));
            disp(data_file);
            disp(strcat("For subject:",subject_info.name));            
            fprintf(2,strcat('BC-V-->> Error: It is posible the subject do not have a preprocessed data.\n'));
            fprintf(2,strcat('OR\n'));
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

