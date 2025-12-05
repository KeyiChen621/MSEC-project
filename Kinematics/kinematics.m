%% 3D Line Plot + Spheres Visualization with Custom Colors
figure;
hold on;

% Define a custom color gradient for each group (using RGB values)
baseColors = [
    255, 224, 204;  % Color 1
    255, 179, 128;  % Color 2
    255, 112, 67;   % Color 3
    214, 40, 40     % Color 4
] / 255;  % Normalize RGB values

% Calculate the number of lines to plot (every two rows form a line)
nLines = ceil(size(points, 1) / 2);

% Generate the interpolation parameters
stopPositions = linspace(0, 1, 4);
interpPositions = linspace(0, 1, nLines);

% Interpolate to create the full gradient colormap
cmap = interp1(stopPositions', baseColors, interpPositions', 'linear');

% Plot the 3D line and spheres for each group
lineIdx = 1;
for i = 1:3:size(points, 1)
    % Extract X, Y, Z coordinates of 5 points
    x_values = points(i, 1:3:13);
    y_values = points(i, 2:3:14);
    z_values = points(i, 3:3:15);
    
    % Generate mirrored X coordinates (mirrored along the Z-axis)
    x_values_mirror = -x_values;
    
    % Assign color based on the group index
    if i >= 1 && i <= 16
        color = [162/255, 38/255, 100/255]; % #B64848
    elseif i >= 17 && i <= 25
        color = [236/255, 236/255, 237/255]; % #4472A0
    elseif i >= 26 && i <= 33
        color = [78/255, 208/255, 245/255]; % #4472A0
    elseif i >= 34 && i <= 52
        color = [236/255, 236/255, 237/255]; % #B64848
    elseif i >= 53 && i <= 107
        color = [162/255, 38/255, 100/255]; % #B64848
    elseif i >= 108 && i <= 173
        color = [236/255, 236/255, 237/255]; % #4472A0
    elseif i >= 174 && i <= 217
        color = [78/255, 208/255, 245/255]; % #4472A0
    elseif i >= 218 && i <= 243
        color = [236/255, 236/255, 237/255]; % #B64848
    elseif i >= 245 && i <= 302
        color = [162/255, 38/255, 100/255]; % #B64848
    elseif i >= 303 && i <= 324
        color = [236/255, 236/255, 237/255]; % #4472A0
    end
    
    % Plot the 3D line connecting the 5 points
    plot3(x_values_mirror, y_values, z_values, '-', 'Color', color, 'LineWidth', 2);
    
    % Add spheres with Phong lighting at each point
    [X, Y, Z] = sphere(50);
    for j = 1:length(x_values)
        % Draw solid spheres
        s = surf(X * 1.5 + x_values_mirror(j), Y * 1.5 + y_values(j), Z * 1.5 + z_values(j));
        s.EdgeColor = 'none';
        s.AmbientStrength = 0.3; % Ambient light intensity, controlling the base brightness of the sphere
        s.DiffuseStrength = 0.8; % Diffuse reflection intensity, controlling the surface brightness based on light source
        s.SpecularStrength = 0.9; % Specular reflection intensity, controlling the shine effect on the surface
        s.SpecularExponent = 25; % Specular exponent, controlling the concentration of the highlight
        s.FaceColor = color; % Set the sphere surface color
        s.FaceLighting = 'phong'; % Apply Phong lighting model for smoother gloss effects
    end
    
    lineIdx = lineIdx + 1;
end

% Add multiple light sources to enhance the 3D effect
l1 = light;
l1.Color = [1 1 1];
l1.Position = [1 0 1];

l2 = light;
l2.Color = [1 1 1];
l2.Position = [-1 0 1];

l3 = light;
l3.Color = [1 1 1];
l3.Position = [0 1 1];

% Set axis properties and aesthetics
axis equal; % Ensure equal scaling on all axes so the spheres appear round
view([0 1 0]);
set(gca, 'XTick', [], 'YTick', [], 'ZTick', []); % Remove axis ticks but keep the background
set(gca, 'box', 'off', 'XColor', 'none', 'YColor', 'none', 'ZColor', 'none'); % Remove axis lines and colors
hold off;


