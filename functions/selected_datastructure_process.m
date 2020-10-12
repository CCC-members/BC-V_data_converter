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
                            sStudy = protocol.ProtocolStudies.Study(k);
                            if(isempty(sStudy.iChannel))
                                sStudy.iChannel = 1;
                            end
                            if(isequal(fileparts(sStudy.BrainStormSubject),subject.Name) && ~isempty(sStudy.iChannel) && ~isempty(sStudy.iHeadModel))                               
                                ChannelsFile = fullfile(protocol_data_path,sStudy.Channel(sStudy.iChannel).FileName);
                                disp ("-->> Genering leadfield file");
                                [HeadModels,iHeadModel,modality] = get_headmodels(protocol_data_path,sStudy);
                                                                                         
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
                        [Sc,iCortex] = get_surfaces(protocol_anat_path,subject);
                        
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
                                filepath = strrep(selected_data_format.preprocessed_data.file_location,'SubID',subject.Name);
                                base_path =  strrep(selected_data_format.preprocessed_data.base_path,'SubID',subject.Name);
                                data_file = fullfile(base_path,filepath);
                                if(isfile(data_file))
                                    [subject_info,HeadModels,Cdata] = load_preprocessed_data(subject_info,selected_data_format,output_subject_dir,data_file,HeadModels,Cdata);
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
                                sStudy = protocol.ProtocolStudies.Study(k);
                                if(isempty(sStudy.iChannel))
                                    sStudy.iChannel = 1;
                                end
                                if(isequal(fileparts(sStudy.BrainStormSubject),template.Name) && ~isempty(sStudy.iChannel) && ~isempty(sStudy.iHeadModel))
                                    ChannelsFile = fullfile(protocol_data_path,sStudy.Channel(sStudy.iChannel).FileName);
                                    disp ("-->> Genering leadfield file");
                                    disp ("-->> Genering leadfield file");
                                    [HeadModels,iHeadModel,modality] = get_headmodels(protocol_data_path,sStudy);                                    
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
                            %                             CortexFile64K           = fullfile(protocol_anat_path, template.Surface(1).FileName);
                            %                             Sc64k                   = load(CortexFile64K);
                            %                             CortexFile8K            = fullfile(protocol_anat_path, template.Surface(template.iCortex).FileName);
                            %                             Sc8k                    = load(CortexFile8K);
                            
                            % Finding near FSAve vertices on subject surface
                            %                             sub_to_FSAve = find_interpolation_vertices(Sc64k,Sc8k, fsave_inds_template);
                            sub_to_FSAve = [];
                            
                            % Loadding subject surfaces
                            [Sc,iCortex] = get_surfaces(protocol_anat_path,template);
                            
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
                                subject_info.name = subject.name;
                            end
                            
                            if(isfield(selected_data_format, 'preprocessed_data'))
                                if(~isequal(selected_data_format.preprocessed_data.base_path,'none'))
                                    filepath = strrep(selected_data_format.preprocessed_data.file_location,'SubID',subject.name);
                                    base_path =  strrep(selected_data_format.preprocessed_data.base_path,'SubID',subject.name);
                                    data_file = fullfile(base_path,filepath);
                                    if(isfile(data_file))
                                       [subject_info,HeadModels,Cdata] = load_preprocessed_data(subject_info,selected_data_format,output_subject_dir,data_file,HeadModels,Cdata);
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