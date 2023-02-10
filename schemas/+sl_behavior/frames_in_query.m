function frames = frames_in_query(q)
q_struct = fetch(q,'frame','duration');
frames = [];
for i=1:length(q_struct)
    frames = [frames, q_struct(i).frame:q_struct(i).frame+q_struct(i).duration-1];
end
frames = unique(frames)';