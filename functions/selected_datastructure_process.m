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
                    disp('BST-P ->> Uploading Subject files into BrainStorm Protocol.');
                    disp("=====================================================================");
                    protocol = load(fullfile(protocols(i).folder,protocols(i).name));
                    protocol_base_path = fileparts(protocols(i).folder);
                    protocol_data_path = protocols(i).folder;
                    protocol_anat_path = fullfile(protocol_base_path,'anat');
                    for j=1: length(protocol.ProtocolSubjects.Subject)
                        subject = protocol.ProtocolSubjects.Subject(j);
                        disp(strcat("-->> Processing subject: ",subject.Name));
                        disp("---------------------------------------------------------------------");
                        for k=1: length(protocol.ProtocolStudies.Study)
                            study = protocol.ProtocolStudies.Study(k);
                            if(isempty(sStudy.iChannel))
                                sStudy.iChannel = 1;
                            end
                            if(isequal(fileparts(study.BrainStormSubject),subject.Name) && ~isempty(study.iChannel) && ~isempty(study.iHeadModel))                               
                                ChannelsFile = fullfile(protocol_data_path,study.Channel(study.iChannel).FileName);
                                disp ("-->> Genering leadfield file");
                                HeadModels = struct;
                                iHeadModel = sStudy.iHeadModel;
                                for h=1: length(study.HeadModel)
                                    HeadModelFile               = fullfile(protocol_data_path,study.HeadModel(h).FileName);
                                    HeadModel                   = load(HeadModelFile);
                                    
                                    HeadModels(h).Comment       = HeadModel.Comment;
                                    HeadModels(h).Ke            = HeadModel.Gain;
                                    HeadModels(h).HeadModelType = HeadModel.HeadModelType;
                                    HeadModels(h).GridOrient    = HeadModel.GridOrient;
                                    HeadModels(h).GridAtlas     = HeadModel.GridAtlas;
                                    HeadModels(h).History       = HeadModel.History;
                                    
                                    if(~isempty(study.HeadModel(h).EEGMethod))
                                        HeadModels(h).Method    = study.HeadModel(h).EEGMethod;
                                    elseif(~isempty(study.HeadModel(h).MEGMethod))
                                        HeadModels(h).Method    = study.HeadModel(h).MEGMethod;
                                    else
                                        HeadModels(h).Method    = study.HeadModel(h).ECOGMethod;
                                    end
                                    
                                end
                                modality = char(study.Channel.Modalities);
                                break;
                            end
                        end
                        %%
                        %% Genering surf file
                        %%
                        disp ("-->> Getting FSAve surface corregistration");
                        % Loadding FSAve templates
                        FSAve_64k               = load('templates/FSAve_cortex_64k.mat');
                        fsave_inds_template     = load('templates/FSAve_64k_8k_coregister_inds.mat');
                        
                        % Loadding subject surfaces
                        CortexFile64K           = fullfile(protocol_anat_path, subject.Surface(1).FileName);
                        Sc64k                   = load(CortexFile64K);
                        CortexFile8K            = fullfile(protocol_anat_path, subject.Surface(subject.iCortex).FileName);
                        Sc8k                    = load(CortexFile8K);
                        
                        % Finding near FSAve vertices on subject surface                        
                        sub_to_FSAve = find_interpolation_vertices(Sc64k,Sc8k, fsave_inds_template);
                        
                        % Loadding subject surfaces
                        disp ("-->> Genering surf file");
                        Sc      = struct([]);                        
                        count   = 1;
                        for h=1:length(subject.Surface)
                            surface = subject.Surface(h);
                            if(isequal(surface.SurfaceType,'Cortex'))
                                if(isequal(subject.iCortex,h))
                                    iCortex = count;
                                end
                                CortexFile              = fullfile(protocol_anat_path, surface.FileName);
                                Cortex                  = load(CortexFile);
                                Sc(count).Comment       = Cortex.Comment;
                                Sc(count).Vertices      = Cortex.Vertices;
                                Sc(count).Faces         = Cortex.Faces;
                                Sc(count).VertConn      = Cortex.VertConn;
                                Sc(count).VertNormals   = Cortex.VertNormals;
                                Sc(count).Curvature     = Cortex.Curvature;
                                Sc(count).SulciMap      = Cortex.SulciMap;
                                Sc(count).Atlas         = Cortex.Atlas;
                                Sc(count).iAtlas        = Cortex.iAtlas;
                                count                   = count + 1;
                            end
                        end                        
                        
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
                        disp(strcat("-->> Creating subject output structure"));
                        [output_subject_dir] = create_data_structure(selected_data_format.BCV_work_dir,subject.Name,modality);
                        
                        subject_info = struct;
                        if(isfolder(output_subject_dir))
                            leadfield_dir = struct;
                            for h=1:length(HeadModels)
                                HeadModel = HeadModels(h);
                                dirref = replace(fullfile('leadfield',strcat(HeadModel.Comment,'_',num2str(posixtime(datetime(HeadModel.History{1}))),'.mat')),'\','/');
                                leadfield_dir(h).path = dirref;
                            end
                            subject_info.leadfield_dir = leadfield_dir;
                            dirref = replace(fullfile('surf','surf.mat'),'\','/');
                            subject_info.surf_dir = dirref;
                            dirref = replace(fullfile('scalp','scalp.mat'),'\','/');
                            subject_info.scalp_dir = dirref;
                            dirref = replace(fullfile('scalp','innerskull.mat'),'\','/');
                            subject_info.innerskull_dir = dirref;
                            dirref = replace(fullfile('scalp','outerskull.mat'),'\','/');
                            subject_info.outerskull_dir = dirref;
                            subject_info.modality = modality;
                            subject_info.name = subject.Name;
                        end
                        
                        if(isfield(selected_data_format, 'preprocessed_data'))
                            if(~isequal(selected_data_format.preprocessed_data.base_path,'none'))
%                                                                 subject.Name = strrep(subject.Name,'sub-MC00000','sub-CBM000');
                                filepath = strrep(selected_data_format.preprocessed_data.file_location,'SubID',subject.Name);
                                base_path =  strrep(selected_data_format.preprocessed_data.base_path,'SubID',subject.Name);
                                data_file = fullfile(base_path,filepath);
                                if(isfile(data_file))
                                    if(isequal(selected_data_format.modality,'EEG'))
                                        disp ("-->> Genering eeg file");
                                        [hdr, data] = import_eeg_format(data_file,selected_data_format.preprocessed_data.format); % Include in this function new dataset
                                        if(~isequal(selected_data_format.preprocessed_data.labels_file_path,"none"))
                                            user_labels = jsondecode(fileread(selected_data_format.preprocessed_data.labels_file_path));
                                            disp ("-->> Cleanning EEG bad Channels by user labels");
                                            [data,hdr]  = remove_eeg_channels_by_labels(user_labels,data,hdr);
                                        end
                                        labels = hdr.label;                                       
                                        for h=1:length(HeadModels)
                                            HeadModel = HeadModels(h);
                                            disp ("-->> Removing Channels  by preprocessed EEG");
                                            [Cdata_r,Ke] = remove_channels_and_leadfield_from_layout(labels,Cdata,HeadModel.Ke);
                                            disp ("-->> Sorting Channels and LeadField by preprocessed EEG");
                                            [Cdata_s,Ke] = sort_channels_and_leadfield_by_labels(labels,Cdata_r,Ke);
                                            HeadModels(h).Ke = Ke;
                                        end
                                        Cdata = Cdata_s;
                                        dirref = replace(fullfile('eeg','eeg.mat'),'\','/');
                                        subject_info.eeg_dir = dirref;
                                        dirref = replace(fullfile('eeg','eeg_info.mat'),'\','/');
                                        subject_info.eeg_info_dir = dirref;
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
                                        
                                        dirref = replace(fullfile('meg','meg.mat'),'\','/');
                                        subject_info.meg_dir = dirref;
                                        dirref = replace(fullfile('meg','meg_info.mat'),'\','/');
                                        subject_info.meg_info_dir = dirref;
                                        dirref = replace(fullfile('meg','trials.mat'),'\','/');
                                        subject_info.trials_dir = dirref;
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
                            HeadModel   = HeadModels(h);
                            Comment     = HeadModel.Comment;
                            Method      = HeadModel.Method;
                            Ke          = HeadModel.Ke;
                            GridOrient  = HeadModel.GridOrient;
                            GridAtlas   = HeadModel.GridAtlas;
                            History     = HeadModel.History;
                            disp ("-->> Saving leadfield file");
                            save(fullfile(output_subject_dir,'leadfield',strcat(HeadModel.Comment,'_',num2str(posixtime(datetime(History{1}))),'.mat')),...
                                'Comment','Method','Ke','GridOrient','GridAtlas','iHeadModel','History');
                        end
                        disp ("-->> Saving surf file");
                        save(fullfile(output_subject_dir,'surf','surf.mat'),'Sc','sub_to_FSAve','iCortex');
                        disp ("-->> Saving scalp file");
                        save(fullfile(output_subject_dir,'scalp','scalp.mat'),'Cdata','Sh');
                        disp ("-->> Saving inner skull file");
                        save(fullfile(output_subject_dir,'scalp','innerskull.mat'),'Sinn');
                        disp ("-->> Saving outer skull file");
                        save(fullfile(output_subject_dir,'scalp','outerskull.mat'),'Sout');
                        disp ("-->> Saving subject file");
                        save(fullfile(output_subject_dir,'subject.mat'),'subject_info');
                        disp("---------------------------------------------------------------------");
                    end
                end
            end
        else
            disp('No one protocol in this foldes:');
            disp('C:\Users\Ariosky\.brainstorm\local_db');
        end
    end
elseif(isequal(selected_data_format.id,'BrainStormTemplate') && is_checked_datastructure_properties(selected_data_format) )
    template_path = selected_data_format.template_path;
    if(isfolder(template_path))
        protocols = dir(fullfile(template_path,'**','protocol.mat'));
        if(~isempty(protocols))
            for i = 1: length(protocols)
                if(~protocols(i).isdir)
                    %% Uploding Subject file into BrainStorm Protocol
                    disp('BST-P ->> Uploading Subject files into BrainStorm Protocol.');
                    disp("=====================================================================");
                    protocol = load(fullfile(protocols(i).folder,protocols(i).name));
                    protocol_base_path = fileparts(protocols(i).folder);
                    protocol_data_path = protocols(i).folder;
                    protocol_anat_path = fullfile(protocol_base_path,'anat');
                    for j=1: length(protocol.ProtocolSubjects.Subject)
                        template = protocol.ProtocolSubjects.Subject(j); 
                        if(isfield(selected_data_format,"subject_name") && ~isempty(selected_data_format.subject_name) ...
                                && ~isequal(selected_data_format.subject_name,"none"))
                            if(~isequal(template.Name,selected_data_format.subject_name))
                                continue;
                            end
                        end
                        prepro_data_paths = dir(strrep(selected_data_format.preprocessed_data.base_path,'SubID',''));
                        prepro_data_paths(ismember( {prepro_data_paths.name}, {'.', '..'})) = [];  %remove . and ..
                        for m=1:length(prepro_data_paths)
                            subject = prepro_data_paths(m);                            
                            disp(strcat("-->> Processing subject: ",subject.name));
                            disp("---------------------------------------------------------------------");
                            for k=1: length(protocol.ProtocolStudies.Study)
                                study = protocol.ProtocolStudies.Study(k);
                                if(isequal(fileparts(study.BrainStormSubject),template.Name) && ~isempty(study.iChannel) && ~isempty(study.iHeadModel))
                                    ChannelsFile = fullfile(protocol_data_path,study.Channel(study.iChannel).FileName);
                                    disp ("-->> Genering leadfield file");
                                    HeadModels = struct;
                                    modality = char(study.Channel.Modalities);
                                    for h=1: length(study.HeadModel)
                                        HeadModelFile = fullfile(protocol_data_path,study.HeadModel(h).FileName);
                                        HeadModel = load(HeadModelFile);
                                        
                                        HeadModels(h).Comment = study.HeadModel(h).Comment;
                                        HeadModels(h).Ke = HeadModel.Gain;
                                        HeadModels(h).GridOrient = HeadModel.GridOrient;
                                        HeadModels(h).GridAtlas = HeadModel.GridAtlas;
                                        if(~isempty(study.HeadModel(h).EEGMethod))
                                            HeadModels(h).Method    = study.HeadModel(h).EEGMethod;
                                        elseif(~isempty(study.HeadModel(h).MEGMethod))
                                            HeadModels(h).Method    = study.HeadModel(h).MEGMethod;
                                        else
                                            HeadModels(h).Method    = study.HeadModel(h).ECOGMethod;
                                        end
                                    end 
                                    jump = false;
                                    break;
                                end
                                jump = true;
                                
                            end
                            if(jump)
                                break;
                            end
                            %%
                            %% Genering surf file
                            %%
                            disp ("-->> Genering surf file");
                            % Loadding FSAve templates
                            FSAve_64k               = load('templates/FSAve_cortex_64k.mat');
                            fsave_inds_template     = load('templates/FSAve_64k_8k_coregister_inds.mat');
                            
                            % Loadding subject surfaces
                            Sc      = struct([]);
                            
                            count   = 1;
                            for h=1:length(template.Surface)
                                surface = template.Surface(h);
                                if(isequal(surface.SurfaceType,'Cortex'))
                                    if(isequal(template.iCortex,h))
                                        iCortex = count;
                                    end
                                    CortexFile              = fullfile(protocol_anat_path, surface.FileName);
                                    Cortex                  = load(CortexFile);
                                    Sc(count).Comment       = Cortex.Comment;
                                    Sc(count).Vertices      = Cortex.Vertices;
                                    Sc(count).Faces         = Cortex.Faces;
                                    Sc(count).VertConn      = Cortex.VertConn;
                                    Sc(count).VertNormals   = Cortex.VertNormals;
                                    Sc(count).Curvature     = Cortex.Curvature;
                                    Sc(count).SulciMap      = Cortex.SulciMap;
                                    Sc(count).Atlas         = Cortex.Atlas;
                                    Sc(count).iAtlas        = Cortex.iAtlas;
                                    count                   = count + 1;
                                end
                            end
                            % Finding near FSAve vertices on template surface
                            sub_to_FSAve = [];
                                                       
                            %%
                            %% Genering Channels file
                            %%
                            disp ("-->> Genering channels file");
                            Cdata = load(ChannelsFile);
                            
                            %%
                            %% Genering scalp file
                            %%
                            disp ("-->> Genering scalp file");
                            ScalpFile               = fullfile(protocol_anat_path,template.Surface(template.iScalp).FileName);
                            Sh = load(ScalpFile);
                            
                            %%
                            %% Genering inner skull file
                            %%
                            disp ("-->> Genering inner skull file");
                            InnerSkullFile          = fullfile(protocol_anat_path,template.Surface(template.iInnerSkull).FileName);
                            Sinn = load(InnerSkullFile);
                            
                            %%
                            %% Genering outer skull file
                            %%
                            disp ("-->> Genering outer skull file");
                            OuterSkullFile          = fullfile(protocol_anat_path,template.Surface(template.iOuterSkull).FileName);
                            Sout = load(OuterSkullFile);
                            
                            %% Creating template subject structure
                            disp(strcat("-->> Creating template output structure"));
                            [output_subject_dir] = create_data_structure(selected_data_format.BCV_work_dir,subject.name,modality);
                            
                            template_info = struct;
                            if(isfolder(output_subject_dir))
                                leadfield_dir = struct;
                                for h=1:length(HeadModels)
                                    HeadModel = HeadModels(h);
                                    dirref = replace(fullfile('leadfield',strcat(HeadModel.Comment,'.mat')),'\','/');
                                    leadfield_dir(h).path = dirref;
                                end
                                subject_info.leadfield_dir = leadfield_dir;
                                dirref = replace(fullfile('surf','surf.mat'),'\','/');
                                subject_info.surf_dir = dirref;
                                dirref = replace(fullfile('scalp','scalp.mat'),'\','/');
                                subject_info.scalp_dir = dirref;
                                dirref = replace(fullfile('scalp','innerskull.mat'),'\','/');
                                subject_info.innerskull_dir = dirref;
                                dirref = replace(fullfile('scalp','outerskull.mat'),'\','/');
                                subject_info.outerskull_dir = dirref;
                                subject_info.modality = modality;
                                subject_info.name = subject.name;
                            end
                            
                            if(isfield(selected_data_format, 'preprocessed_data'))
                                if(~isequal(selected_data_format.preprocessed_data.base_path,'none'))
                                    %                                 name = strrep(subject.Name,'sub-MC00000','sub-CBM000');%                                   
                                    filepath = strrep(selected_data_format.preprocessed_data.file_location,'SubID',subject.name);
                                    base_path =  strrep(selected_data_format.preprocessed_data.base_path,'SubID',subject.name);
                                    data_file = fullfile(base_path,filepath);
                                    if(isfile(data_file))
                                        if(isequal(selected_data_format.modality,'EEG'))
                                            disp ("-->> Genering eeg file");                                            
                                            [hdr, data] = import_eeg_format(data_file,selected_data_format.preprocessed_data.format);                                            
                                            if(~isequal(selected_data_format.preprocessed_data.labels_file_path,"none"))
                                                user_labels = jsondecode(fileread(selected_data_format.preprocessed_data.labels_file_path));
                                                disp ("-->> Cleanning EEG bad Channels by user labels");
                                                [data,hdr]  = remove_eeg_channels_by_labels(user_labels,data,hdr);
                                            end
                                            labels = hdr.label;                                           
                                            for h=1:length(HeadModels)
                                                HeadModel = HeadModels(h);
                                                disp ("-->> Removing Channels  by preprocessed EEG");
                                                [Cdata_r,Ke] = remove_channels_and_leadfield_from_layout(labels,Cdata,HeadModel.Ke);
                                                disp ("-->> Sorting Channels and LeadField by preprocessed EEG");
                                                [Cdata_s,Ke] = sort_channels_and_leadfield_by_labels(labels,Cdata_r,Ke);
                                                HeadModels(h).Ke = Ke;
                                            end
                                            Cdata = Cdata_s;
                                            dirref = replace(fullfile('eeg','eeg.mat'),'\','/');
                                            subject_info.eeg_dir = dirref;
                                            dirref = replace(fullfile('eeg','eeg_info.mat'),'\','/');
                                            subject_info.eeg_info_dir = dirref;
                                            disp ("-->> Saving eeg_info file");
                                            save(fullfile(output_subject_dir,'eeg','eeg_info.mat'),'hdr');
                                            disp ("-->> Saving eeg file");
                                            save(fullfile(output_subject_dir,'eeg','eeg.mat'),'data');                                        
                                        end
                                    end
                                end
                            end
                            for h=1:length(HeadModels)
                                Comment     = HeadModels(h).Comment;
                                Method      = HeadModels(h).Method;
                                Ke          = HeadModels(h).Ke;
                                GridOrient  = HeadModels(h).GridOrient;
                                GridAtlas   = HeadModels(h).GridAtlas;
                                disp ("-->> Saving leadfield file");
                                save(fullfile(output_subject_dir,'leadfield',strcat(Comment,'.mat')),'Comment','Method','Ke','GridOrient','GridAtlas');
                            end
                            disp ("-->> Saving surf file");
                            save(fullfile(output_subject_dir,'surf','surf.mat'),'Sc','sub_to_FSAve','iCortex');
                            disp ("-->> Saving scalp file");
                            save(fullfile(output_subject_dir,'scalp','scalp.mat'),'Cdata','Sh');
                            disp ("-->> Saving inner skull file");
                            save(fullfile(output_subject_dir,'scalp','innerskull.mat'),'Sinn');
                            disp ("-->> Saving outer skull file");
                            save(fullfile(output_subject_dir,'scalp','outerskull.mat'),'Sout');
                            disp ("-->> Saving subject file");
                            save(fullfile(output_subject_dir,'subject.mat'),'subject_info');
                            disp("---------------------------------------------------------------------");
                        end
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

end