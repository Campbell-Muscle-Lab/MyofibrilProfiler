function par_lines
line_x = linspace(0,10,200);

line_y = linspace(5,10,200);

m = (line_y(2) - line_y(1))/(line_x(2) - line_x(1))

c = line_y(1) - m*line_x(1)

alpha = atan(m)
x = 1;
sin(alpha)*cos(alpha)

par_x = line_x;

par_y = line_y + x
m = (par_y(2) - par_y(1))/(par_x(2) - par_x(1))


p = -x*sin(alpha)*cos(alpha) + par_x(1);
p_y = -x*sin(alpha)*sin(alpha) + par_y(1);
clf
plot(line_x,line_y)
hold on
plot(par_x,par_y,'o')

plot(p,p_y,'gd','LineStyle','none')
xlim([0 10])
ylim([0 10])

% 
% par_y = []
% par_x = []
par_x = line_x + sin(alpha)*1;
% 
% par_y = line_y - 0.1 ;
m = (par_y(2) - par_y(1))/(par_x(2) - par_x(1))
% plot(par_x,par_y,'dg')

end