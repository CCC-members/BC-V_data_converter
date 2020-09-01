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
                    %% Uploding Subject file into BrainStorm Protocol
                    disp('BST-P ->> Uploding Subject file into BrainStorm Protocol.');
                    protocol = load(fullfile(protocols(i).folder,protocols(i).name));
                    protocol_base_path = fileparts(protocols(i).folder);
                    protocol_data_path = protocols(i).folder;
                    protocol_anat_path = fullfile(protocol_base_path,'anat');
                    for j=1: length(protocol.ProtocolSubjects.Subject)
                        subject = protocol.ProtocolSubjects.Subject(j);                        
                        for k=1: length(protocol.ProtocolStudies.Study)
                            study = protocol.ProtocolStudies.Study(k);
                            if(isequal(fileparts(study.BrainStormSubject),subject.Name) && ~isempty(study.iChannel) && ~isempty(study.iHeadModel))
                                ChannelsFile = fullfile(protocol_data_path,study.Channel(study.iChannel).FileName);
                                disp ("-->> Genering leadfield file");
                                HeadModels = struct;
                                for h=1: length(study.HeadModel)
                                    HeadModelFile = fullfile(protocol_data_path,study.HeadModel(h).FileName);
                                    HeadModel = load(HeadModelFile);
                                    
                                    HeadModels(h).Comment = study.HeadModel(h).Comment;
                                    HeadModels(h).Ke = HeadModel.Gain;
                                    HeadModels(h).GridOrient = HeadModel.GridOrient;
                                    HeadModels(h).GridAtlas = HeadModel.GridAtlas;
                                    
                                end
                                modality = char(study.Channel.Modalities);
                                break;
                            end
                        end
                        %%
                        %% Genering surf file
                        %%
                        disp ("-->> Genering surf file");
                        % Loadding FSAve templates
                        FSAve_64k               = load('templates/FSAve_cortex_64k.mat');
                        fsave_inds_template     = load('templates/FSAve_64k_8k_coregister_inds.mat');
                        
                        % Loadding subject surfaces
                        CortexFile64K           = fullfile(protocol_anat_path, subject.Surface(1).FileName);                        
                        Sc64k                   = load(BSTCortexFile64K);
                        CortexFile8K            = fullfile(protocol_anat_path, subject.Surface(2).FileName);
                        BSTCortexFile8K         = bst_fullfile(ProtocolInfo.SUBJECTS, CortexFile8K);
                        Sc8k                    = load(BSTCortexFile8K);

                        % Finding near FSAve vertices on subject surface
                        sub_to_FSAve = find_interpolation_vertices(Sc64k,Sc8k, fsave_inds_template);

                        
                        %%
                        %% Genering Channels file
                        %%
                        disp ("-->> Genering channels file");
                        Cdata = load(ChannelsFile);
                        
                        %%
                        %% Genering scalp file
                        %%
                        disp ("-->> Genering scalp file");
                        ScalpFile               = fullfile(protocol_anat_path,subject.Surface(subject.iScalp).FileName);
                        Sh = load(ScalpFile);
                        
                        %%
                        %% Genering inner skull file
                        %%
                        disp ("-->> Genering inner skull file");
                        InnerSkullFile          = fullfile(protocol_anat_path,subject.Surface(subject.iInnerSkull).FileName);
                        Sinn = load(InnerSkullFile);
                        
                        %%
                        %% Genering outer skull file
                        %%
                        disp ("-->> Genering outer skull file");
                        OuterSkullFile          = fullfile(protocol_anat_path,subject.Surface(subject.iOuterSkull).FileName);
                        Sout = load(OuterSkullFile);
                        
                        %% Creating subject folder structure
                        disp(strcat("Saving BC-VARETA structure. Subject: ",subject.Name));
                        [output_subject_dir] = create_data_structure(selected_data_format.BCV_work_dir,subject.Name,modality);
                        
                        subject_info = struct;
                        if(isfolder(output_subject_dir))
                            leadfield_dir = struct;
                            for h=1:length(HeadModels)
                                HeadModel = HeadModels(h);
                                if(isequal(HeadModel.Comment,'Overlapping spheres'))
                                    dir = replace(fullfile('leadfield','os_leadfield.mat'),'\','/');
                                    leadfield_dir(h).path = dir;
                                end
                                if(isequal(HeadModel.Comment,'Single sphere'))
                                    dir = replace(fullfile('leadfield','ss_leadfield.mat'),'\','/');
                                    leadfield_dir(h).path = dir;
                                end
                                if(isequal(HeadModel.Comment,'OpenMEEG BEM'))
                                    dir = replace(fullfile('leadfield','om_leadfield.mat'),'\','/');
                                    leadfield_dir(h).path = dir;
                                end
                            end
                            subject_info.leadfield_dir = leadfield_dir;
                            dir = replace(fullfile('surf','surf.mat'),'\','/');
                            subject_info.surf_dir = dir;
                            dir = replace(fullfile('scalp','scalp.mat'),'\','/');
                            subject_info.scalp_dir = dir;
                            dir = replace(fullfile('scalp','innerskull.mat'),'\','/');
                            subject_info.innerskull_dir = dir;
                            dir = replace(fullfile('scalp','outerskull.mat'),'\','/');
                            subject_info.outerskull_dir = dir;
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
                                        [hdr, data] = import_eeg_format(eeg_file,selected_data_set.preprocessed_eeg.format); % Include in this function new dataset
                                        if(~isequal(selected_data_set.process_import_channel.channel_label_file,"none"))
                                            user_labels = jsondecode(fileread(selected_data_set.process_import_channel.channel_label_file));
                                            disp ("-->> Cleanning EEG bad Channels by user labels");
                                            [data,hdr]  = remove_eeg_channels_by_labels(user_labels,data,hdr);
                                        end
                                        labels = hdr.label;
                                        labels = strrep(labels,'REF','');
                                        for h=1:length(HeadModels)
                                            HeadModel = HeadModels(h);
                                            disp ("-->> Removing Channels  by preprocessed EEG");
                                            [Cdata_r,Ke] = remove_channels_and_leadfield_from_layout(labels,Cdata,HeadModel.Ke);
                                            disp ("-->> Sorting Channels and LeadField by preprocessed EEG");
                                            [Cdata_s,Ke] = sort_channels_and_leadfield_by_labels(labels,Cdata_r,Ke);
                                            HeadModels(h).Ke = Ke;
                                        end
                                        Cdata = Cdata_s;
                                        dir = replace(fullfile('eeg','eeg.mat'),'\','/');
                                        subject_info.eeg_dir = dir;
                                        dir = replace(fullfile('eeg','eeg_info.mat'),'\','/');
                                        subject_info.eeg_info_dir = dir;
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
                                        for h=1:length(HeadModels)
                                            HeadModel = HeadModels(h);
                                            disp ("-->> Removing Channels by preprocessed MEG");
                                            [Cdata_r,Ke] = remove_channels_and_leadfield_from_layout(label,Cdata,HeadModel.Ke);
                                            disp ("-->> Sorting Channels and LeadField by preprocessed MEG");
                                            [Cdata_s,Ke] = sort_channels_and_leadfield_by_labels(label,Cdata_r,Ke);
                                            HeadModels(h).Ke = Ke;
                                        end
                                        Cdata = Cdata_s;
                                        data = [meg.data.trial];
                                        trials = meg.data.trial;
                                        
                                        dir = replace(fullfile('meg','meg.mat'),'\','/');
                                        subject_info.meg_dir = dir;
                                        dir = replace(fullfile('meg','meg_info.mat'),'\','/');
                                        subject_info.meg_info_dir = dir;
                                        dir = replace(fullfile('meg','trials.mat'),'\','/');
                                        subject_info.trials_dir = dir;
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
                        for h=1:length(HeadModels)
                            Comment     = HeadModels(h).Comment;
                            Ke          = HeadModels(h).Ke;
                            GridOrient  = HeadModels(h).GridOrient;
                            GridAtlas   = HeadModels(h).GridAtlas;
                            disp ("-->> Saving leadfield file");
                            if(isequal(Comment,'Overlapping spheres'))
                                save(fullfile(output_subject_dir,'leadfield','os_leadfield.mat'),'Comment','Ke','GridOrient','GridAtlas');
                            end
                            if(isequal(Comment,'Single sphere'))
                                save(fullfile(output_subject_dir,'leadfield','ss_leadfield.mat'),'Comment','Ke','GridOrient','GridAtlas');
                            end
                            if(isequal(HeadModel.Comment,'OpenMEEG BEM'))
                                save(fullfile(output_subject_dir,'leadfield','om_leadfield.mat'),'Comment','Ke','GridOrient','GridAtlas');
                            end
                        end
                        disp ("-->> Saving surf file");
                        save(fullfile(output_subject_dir,'surf','surf.mat'),'Sc64k','Sc8k','sub_to_FSAve');
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
elseif(isequal(selected_data_format.id,'chbm_cleanning'))
     clean_eeg_by_user_labels(selected_data_format);
end

disp("-->> Process finished....")

end