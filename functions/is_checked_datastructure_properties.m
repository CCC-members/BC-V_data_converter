function valided = is_checked_datastructure_properties(selected_data_format)

valided = true;
 
if(isequal(selected_data_format.name,'BrainStorm'))
    if(~isfolder(selected_data_format.bst_db_path))
        valided = false;
        fprintf(2,'\n ->> Error: The BrainStorm folder don''t exist\n');
        return;
    end  
end

end

