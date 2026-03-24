function sarc_col = return_color_scheme(col,no_of_sarcomeres)
col_map = rgb2hsv(col);
shade = linspace(col_map(3)*0.5, col_map(3),no_of_sarcomeres);

col_map = repmat(col_map,[no_of_sarcomeres 1]);
col_map(:,3) = shade;

sarc_col = [];
if ~isempty(col_map)
sarc_col = hsv2rgb(col_map);
end
end

