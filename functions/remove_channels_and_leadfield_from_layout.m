function [channel_layout,leadfield] = remove_channels_and_leadfield_from_layout(labels,channel_layout,leadfield)
from = 1;
limit = length(channel_layout.Channel);
while(from <= limit)
    pos = find(strcmpi(channel_layout.Channel(from).Name, labels), 1);
    if (isempty(pos))
        channel_layout.Channel(from)=[];
        leadfield(from,:)=[];
        limit = limit - 1;
    else
        from = from + 1;
    end
end
end

