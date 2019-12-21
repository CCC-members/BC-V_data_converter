function selected_datastructure_process(app_properties)
selected_data_format = app_properties.selected_data_format;
if(isequal(selected_data_format.name,'BrainStorm') && is_checked_datastructure_properties(selected_data_format) )    
    bst_db_path = selected_data_format.bst_db_path;
    if(isfolder(bst_db_path))
        protocols = dir(fullfile(bst_db_path,'**','protocol.mat'));
        if(~isempty(protocols))
            for i = 1: length(protocols)
                if(~protocols(i).isdir)                    
                    protocol = load(fullfile(protocols(i).folder,protocols(i).name));
                    protocol_base_path = fileparts(protocols(i).folder);
                    protocol_data_path = protocols(i).folder;
                    protocol_anat_path = fullfile(protocol_base_path,'anat');
                    for j=1: length(protocol.ProtocolSubjects.Subject)
                        subject = protocol.ProtocolSubjects.Subject(j);
                        CortexFile = fullfile(protocol_anat_path, subject.Surface(subject.iCortex).FileName);
                        ScalpFile =  fullfile(protocol_anat_path,subject.Surface(subject.iScalp).FileName);
%                         InnerSkullFile = fullfile(protocol_anat_path,subject.Surface(subject.iInnerSkull).FileName);
%                         OuterSkullFile = fullfile(protocol_anat_path,subject.Surface(subject.iOuterSkull).FileName);
                        for k=1: length(protocol.ProtocolStudies.Study)
                            study = protocol.ProtocolStudies.Study(k);
                            if(isequal(fileparts(study.BrainStormSubject),subject.Name) && ~isempty(study.Channel))
                                ChannelsFile = fullfile(protocol_data_path,study.Channel.FileName);
                                BSTHeadModelFiles = dir(fullfile(protocol_data_path,fileparts(study.FileName),'headmodel_surf_openmeeg*.mat'));
                                [~,idx] = sort([BSTHeadModelFiles.datenum]);
                                BSTHeadModelFile = BSTHeadModelFiles(idx(end));
                                HeadModelFile = fullfile(BSTHeadModelFile.folder,BSTHeadModelFile.name);
                                break;
                            end
                        end
                        disp(strcat("Saving BC-VARETA structure. Subject: ",subject.Name)); 
                        output_subject_dir = fullfile( app_properties.BCV_work_dir,subject.Name);
                        eeg_dir = fullfile(output_subject_dir,'eeg');
                        leadfield_dir = fullfile(output_subject_dir,'leadfield');
                        surf_dir = fullfile(output_subject_dir,'surf');
                        scalp_dir = fullfile(output_subject_dir,'scalp');
                        if(~isfolder(output_subject_dir))
                            mkdir(output_subject_dir);
                            mkdir(eeg_dir);
                            mkdir(leadfield_dir);
                            mkdir(surf_dir);
                            mkdir(scalp_dir);
                        end                        
                        HeadModel = load(HeadModelFile);                                                
                        Ke = HeadModel.Gain;
                        GridOrient = HeadModel.GridOrient;
                        GridAtlas = HeadModel.GridAtlas;
                        
                        Sc = load(CortexFile);
                        
                        Ceeg = load(ChannelsFile);
                        
                        Sh = load(ScalpFile);
                        
                        if(isfield(selected_data_format, 'preprocessed_eeg'))
                            if(~isequal(selected_data_format.preprocessed_eeg.path,'none'))
                                [filepath,name,ext]= fileparts(selected_data_format.preprocessed_eeg.file_location);
                                file_name = strrep(name,'SubID',subject.Name);
                                eeg_file = fullfile(selected_data_format.preprocessed_eeg.path,subject.Name,filepath,[file_name,ext]);
                                if(isfile(eeg_file))
                                    disp ("-->> Genering eeg file");
                                    [hdr, data] = import_eeg_format(eeg_file,selected_data_format.preprocessed_eeg.format);
                                    labels = hdr.label;
                                    labels = strrep(labels,'REF','');
                                    disp ("-->> Removing Channels  by preprocessed EEG");
                                    [Ceeg,Ke] = remove_channels_and_leadfield_from_layout(labels,Ceeg,Ke);                                  
                                    disp ("-->> Sorting Channels and LeadField by preprocessed EEG");
                                    [Ceeg,Ke] = sort_channels_and_leadfield_by_labels(labels,Ceeg,Ke);
                                    disp ("-->> Saving eeg file");
                                    eeg_path = fullfile(eeg_dir,'eeg.mat');
                                    save(eeg_path,'data');  
                                end
                            end
                        end
                        
                        leadfield_path = fullfile(leadfield_dir,'leadfield.mat');
                        surf_path = fullfile(surf_dir,'surf.mat');
                        scalp_path = fullfile(scalp_dir,'scalp.mat');
                        if(exist(eeg_path))
                            save(fullfile(output_subject_dir,'subject.mat'),'leadfield_path','surf_path','scalp_path','eeg_path');
                        else
                             save(fullfile(output_subject_dir,'subject.mat'),'leadfield_path','surf_path','scalp_path');
                        end
                        disp ("-->> Saving leadfield file");
                        save(leadfield_path,'Ke','GridOrient','GridAtlas');
                        disp ("-->> Saving surface file");
                        save(surf_path,'Sc');
                        disp ("-->> Saving Scalp file");
                        save(scalp_path,'Ceeg','Sh');
                    end
                end
            end
        else
            disp('No one protocol in this foldes:');
            disp('C:\Users\Ariosky\.brainstorm\local_db');
        end
    end
end

disp("-->> Process finished....")

end