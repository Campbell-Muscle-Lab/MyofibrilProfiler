function test_open


image_string = 'data/mouse WT 005.nd2'


d = bfopen(image_string)

h = d{1,1}
% 
% h.get('Global CSU-W1, FilterChanger(EM) #3')

im = h{1};

colormap('gray')
imagesc(im)
u = d{3}

hTable = d{2};

allKeys = arrayfun(@char, hTable.keySet.toArray, 'UniformOutput', false);
allValues = cellfun(@(x) hTable.get(x), allKeys, 'UniformOutput', false);

showTable = table(allKeys, allValues, 'VariableNames', {'Key', 'Value'})


writetable(showTable,'test_nd2.xlsx')



end