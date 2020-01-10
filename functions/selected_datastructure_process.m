function selected_datastructure_process(app_properties)
selected_data_format = app_properties.selected_data_format;
selected_data_format.BCV_work_dir = app_properties.BCV_work_dir;
if(isequal(selected_data_format.id,'BrainStorm') && is_checked_datastructure_properties(selected_data_format) )
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
                        InnerSkullFile = fullfile(protocol_anat_path,subject.Surface(subject.iInnerSkull).FileName);
                        OuterSkullFile = fullfile(protocol_anat_path,subject.Surface(subject.iOuterSkull).FileName);
                        for k=1: length(protocol.ProtocolStudies.Study)
                            study = protocol.ProtocolStudies.Study(k);
                            if(isequal(fileparts(study.BrainStormSubject),subject.Name) && ~isempty(study.iChannel) && ~isempty(study.iHeadModel))
                                ChannelsFile = fullfile(protocol_data_path,study.Channel(study.iChannel).FileName);
                                HeadModelFile = fullfile(protocol_data_path,study.HeadModel(study.iHeadModel).FileName);
                                modality = char(study.Channel.Modalities);
                                break;
                            end
                        end
                        HeadModel = load(HeadModelFile);
                        Ke = HeadModel.Gain;
                        GridOrient = HeadModel.GridOrient;
                        GridAtlas = HeadModel.GridAtlas;
                        
                        Sc = load(CortexFile);
                        
                        Cdata = load(ChannelsFile);
                        
                        Sh = load(ScalpFile);
                        
                        Sinn = load(InnerSkullFile);
                        Sout = load(OuterSkullFile);
                        
                        disp(strcat("Saving BC-VARETA structure. Subject: ",subject.Name));
                        [output_subject_dir] = create_data_structure(selected_data_format.BCV_work_dir,subject.Name,modality);
                        
                        subject_info = struct;
                        if(isfolder(output_subject_dir))
                            subject_info.leadfield_dir = fullfile('leadfield','leadfield.mat');
                            subject_info.surf_dir = fullfile('surf','surf.mat');
                            subject_info.scalp_dir = fullfile('scalp','scalp.mat');
                            subject_info.innerskull_dir = fullfile('scalp','innerskull.mat');
                            subject_info.outerskull_dir = fullfile('scalp','outerskull.mat');
                            subject_info.modality = modality;
                            subject_info.name = subject.Name;
                        end
                        
                        if(isfield(selected_data_format, 'preprocessed_data'))
                            if(~isequal(selected_data_format.preprocessed_data.base_path,'none'))
                                filepath = strrep(selected_data_format.preprocessed_data.file_location,'SubID',subject.Name);
                                base_path =  strrep(selected_data_format.preprocessed_data.base_path,'SubID',subject.Name);
                                data_file = fullfile(base_path,filepath);
                                if(isfile(data_file))
                                    if(isequal(selected_data_format.modality,'EEG'))
                                        disp ("-->> Genering eeg file");
                                        [hdr, data] = import_eeg_format(data_file,selected_data_format.preprocessed_data.format);
                                        labels = hdr.label;
                                        labels = strrep(labels,'REF','');
                                        disp ("-->> Removing Channels  by preprocessed EEG");
                                        [Cdata,Ke] = remove_channels_and_leadfield_from_layout(labels,Cdata,Ke);
                                        disp ("-->> Sorting Channels and LeadField by preprocessed EEG");
                                        [Cdata,Ke] = sort_channels_and_leadfield_by_labels(labels,Cdata,Ke);
                                        
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
                                        
                                        data = [meg.data.trial];
                                        trials = meg.data.trial;
                                        
                                        subject_info.meg_dir = fullfile('meg','meg.mat');
                                        subject_info.meg_info_dir = fullfile('meg','meg_info.mat');
                                        subject_info.trials_dir = fullfile('meg','trials.mat');
                                        disp ("-->> Saving meg_info file");
                                        save(fullfile(output_subject_dir,'meg','meg_info.mat'),'hdr','fsample','trialinfo','grad','time','label','cfg');
                                        disp ("-->> Saving meg file");
                                        save(fullfile(output_subject_dir,'meg','meg.mat'),'data');
                                        disp ("-->> Saving meg trials file");
                                        save(fullfile(output_subject_dir,'meg','trials.mat'),'trials')
                                    end
                                end
                            end
                        end
                        disp ("-->> Saving leadfield file");
                        save(fullfile(output_subject_dir,'leadfield','leadfield.mat'),'Ke','GridOrient','GridAtlas');
                        disp ("-->> Saving surf file");
                        save(fullfile(output_subject_dir,'surf','surf.mat'),'Sc');
                        disp ("-->> Saving scalp file");
                        save(fullfile(output_subject_dir,'scalp','scalp.mat'),'Cdata','Sh');
                        disp ("-->> Saving inner skull file");
                        save(fullfile(output_subject_dir,'scalp','innerskull.mat'),'Sinn');
                        disp ("-->> Saving outer skull file");
                        save(fullfile(output_subject_dir,'scalp','outerskull.mat'),'Sout');
                        disp ("-->> Saving subject file");
                        save(fullfile(output_subject_dir,'subject.mat'),'subject_info');
                    end
                end
            end
        else
            disp('No one protocol in this foldes:');
            disp('C:\Users\Ariosky\.brainstorm\local_db');
        end
    end
elseif(isequal(selected_data_format.id,'ipd'))
    import_preprossed_data(selected_data_format);
end

disp("-->> Process finished....")

end