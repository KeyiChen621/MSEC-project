%% 3D Line Plot + Spheres Visualization with Custom Red Gradient
figure;
hold on;

% Define a custom red gradient colormap (4 colors)
baseColors = [
    255, 224, 204;
    255, 179, 128;
    255, 112, 67;
    214,  40, 40
] / 255;

% Calculate the number of line groups to plot (each pair of rows forms a line)
nLines = ceil(size(points,1)/2);

% Generate parameters for interpolation
stopPositions = linspace(0,1,4);
interpPositions = linspace(0,1,nLines);

% Interpolate to create a full gradient colormap
cmap = interp1(stopPositions', baseColors, interpPositions', 'linear');

% Plot the lines and spheres by group
lineIdx = 1;
for i = 1:2:size(points,1)
    % Extract X/Y/Z coordinates of 5 points
    x_values = points(i,   1:3:7);
    y_values = points(i,   2:3:8);
    z_values = points(i,   3:3:9);
    
    % Current group color
    color = cmap(lineIdx, :);
    
    % Plot 3D line
    plot3(x_values, y_values, z_values, '-', 'Color', color, 'LineWidth', 2);
    
    % Add spheres with Phong shading at each point
    [X, Y, Z] = sphere(50);
    for j = 1:length(x_values)
        s = surf(X*1.5 + x_values(j), Y*1.5 + y_values(j), Z*1.5 + z_values(j));
        s.EdgeColor       = 'none';
        s.AmbientStrength = 0.3;
        s.DiffuseStrength = 0.8;
        s.SpecularStrength = 0.9;
        s.SpecularExponent = 25;
        s.FaceColor       = color;
        s.FaceLighting    = 'phong';
    end
    
    lineIdx = lineIdx + 1;
end

% Add multiple light sources to enhance 3D effect
lightPositions = [1 0 1; -1 0 1; 0 1 1];
for k = 1:size(lightPositions,1)
    l = light;
    l.Color = [1 1 1];
    l.Position = lightPositions(k,:);
end

% View settings and aesthetics
axis equal;
view([0 1 0]);
set(gca, 'XTick', [], 'YTick', [], 'ZTick', []);
set(gca, 'box', 'off', 'XColor', 'none', 'ZColor', 'none');
hold off;
