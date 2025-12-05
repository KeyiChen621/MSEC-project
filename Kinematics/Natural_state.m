%% 3D Line Plot + Spheres Visualization with Uniform Gray Color
figure;
hold on;

% Define a uniform gray color
grayColor = [0.6 0.6 0.6];

% Calculate the number of line groups to plot (each pair of rows forms a line)
nLines = ceil(size(points, 1) / 2);

% Plot the lines and spheres by group
lineIdx = 1;
for i = 1:2:size(points, 1)
    % Extract X, Y, Z coordinates of 5 points
    x_values = points(i, 1:3:7);
    y_values = points(i, 2:3:8);
    z_values = points(i, 3:3:9);
    
    % Plot 3D line with the uniform gray color
    plot3(x_values, y_values, z_values, '-', 'Color', grayColor, 'LineWidth', 2);
    
    % Add spheres with Phong lighting at each point
    [X, Y, Z] = sphere(50);
    for j = 1:length(x_values)
        s = surf(X*1.5 + x_values(j), Y*1.5 + y_values(j), Z*1.5 + z_values(j));
        s.EdgeColor = 'none';
        s.AmbientStrength = 0.3;  % Ambient light intensity, controls the base brightness of the sphere
        s.DiffuseStrength = 0.8;  % Diffuse reflection intensity, controls the brightness on the surface from light
        s.SpecularStrength = 0.9; % Specular reflection intensity, controls the glossiness of the sphere surface
        s.SpecularExponent = 25;  % Specular exponent, controls the sharpness of highlights on the surface
        s.FaceColor = grayColor; % Set the face color of the sphere
        s.FaceLighting = 'phong'; % Apply Phong lighting model to smooth the gloss effect
    end
    
    lineIdx = lineIdx + 1;
end

% Add multiple light sources to enhance 3D effect
lightPositions = [1 0 1; -1 0 1; 0 1 1];
for k = 1:size(lightPositions, 1)
    l = light;
    l.Color = [1 1 1];
    l.Position = lightPositions(k,:);
end

% View settings and aesthetics
axis equal;  % Ensure equal scaling on all axes so spheres appear as perfect circles
view([0 1 0]);  % Set the viewing angle
set(gca, 'XTick', [], 'YTick', [], 'ZTick', []);  % Remove axis ticks
set(gca, 'box', 'off', 'XColor', 'none', 'ZColor', 'none');  % Remove axis lines and colors
hold off;
