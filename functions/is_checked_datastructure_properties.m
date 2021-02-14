function valided = is_checked_datastructure_properties(selected_data_set)

valided = true;
 
if(isequal(selected_data_set.name,'BrainStorm'))
    if(~isfolder(selected_data_set.bst_db_path))
        valided = false;
        fprintf(2,'\n ->> Error: The BrainStorm folder don''t exist\n');
        return;
    end  
end

end

