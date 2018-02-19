function [ x, y ] = straight_mobility ( velocity, seed, Param )
%STRAIGHT_MOBILITY Summary of this function goes here
%   Detailed explanation goes here

rng(seed);

dir = 2 * pi * rand;

v_x = velocity * cos(dir);
v_y = velocity * sin(dir);

if (strcmp(Param.microPos,'clusterized')),
    toss = rand;
    if (toss > 2 / 3),
        buildings = Param.buildings;
        area = [min(buildings(:, 1)), min(buildings(:, 2)), max(buildings(:, 3)), ...
            max(buildings(:, 4))];
        xc = (area(3) - area(1))/2;
        yc = (area(4) - area(2))/2;
        rho = 20 + rand * 230;
        theta = 2 * pi * rand;
        pos = [xc + rho * cos(theta), yc + rho * sin(theta), Param.ueHeight];
    else
        toss = randi(Param.numClusters);
        rho = rand * 70;
        theta = 2 * pi * rand;
        pos = [Param.clusters(toss, :), 0] + [rho * cos(theta), rho * sin(theta) Param.ueHeight];
    end
else
    pos = [randi([Param.area(1),Param.area(3)]) randi([Param.area(2),Param.area(4)]) Param.ueHeight];
end

duration = 60 / Param.mobilityStep * 10; % 10 minutes
x = ones(1, duration) * pos(1) + (1 : duration) * v_x / 1000;
y = ones(1, duration) * pos(2) + (1 : duration) * v_y / 1000;

end