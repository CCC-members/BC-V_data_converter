function [hdr, data] = import_eeg_format(base_path,format)
if(isequal(format,'edf'))
   [hdr, data]= edfread(base_path);
end
if(isequal(format,'plg'))    
%     info_file = dir(fullfile(base_path,'**','*.INF'));
%     info_file = fullfile(info_file.folder,info_file.name);
%     info = read_plginf(info_file);
%     pat_file = dir(fullfile(base_path,'**','*.INF'));
%     pat_file = fullfile(pat_file.folder,pat_file.name);
    [pat_info, inf_info, plg_info, mrk_info, win_info, cdc_info, states_name] = plg2matlab(base_path);
    % creating output structure
    data = plg_info.data;
    
    hdr.pat_info = pat_info;
    hdr.inf_info = inf_info;
    hdr.mrk_info = mrk_info;
    hdr.win_info = win_info;
    hdr.cdc_info = cdc_info;
    hdr.states_name = states_name;    
    
    %% filtring data
    data(20:23,:) = [];    
    hdr.inf_info.PLGMontage = hdr.inf_info.PLGMontage(1:19,:);
end

end

