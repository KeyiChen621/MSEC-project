%% Assumed existing variables (each is a 22 × 8 double matrix)
% off, feed, vision, smell, vision_smell

data_all = {off, feed, vision, smell, vision_smell};  
groupNames = {'MESC-off', 'MESC-on', 'MESC-on (VD)', 'MESC-on (OD)', 'MESC-on (VD+OD)'};

%% RGB color map (5 distinct colors)
colors = lines(5);

%% Plotting settings
baseFontSize   = 22;
axisLineWidth  = 1.5;
nDays          = 22;

figure('Position', [100 100 700 500]); hold on;
axMain = gca;
set(axMain, ...
    'Box', 'on', ...
    'LineWidth', axisLineWidth, ...
    'FontSize', baseFontSize, ...
    'FontWeight', 'bold');

%% Plot mean ± 95% CI for each group
for i = 1:5
    data = data_all{i};      % Current group data matrix (22 × 8)
    mu   = mean(data, 2);    % Mean success rate across animals
    sem  = std(data, 0, 2) ./ sqrt(size(data, 2));   % Standard error
    ci95 = 1.96 * sem;       % 95% confidence interval

    % Shaded CI region
    fill([1:nDays, fliplr(1:nDays)], ...
         [mu + ci95; flipud(mu - ci95)]', ...
         colors(i,:), 'FaceAlpha', 0.2, ...
         'EdgeColor', 'none');

    % Mean curve
    plot(1:nDays, mu, '-', ...
         'Color', colors(i,:), ...
         'LineWidth', 2);
end

%% Labels, limits, and title
xlabel('Training Day', 'FontSize', baseFontSize, 'FontWeight', 'bold');
ylabel('Success Rate', 'FontSize', baseFontSize, 'FontWeight', 'bold');
xlim([1 22]);
xticks(1:2:22);   % Optional: show every other day
title('Risk', 'FontSize', baseFontSize + 2, 'FontWeight', 'bold');

%% Custom legend (5 entries)
legendHandles = gobjects(5,1);
for i = 1:5
    legendHandles(i) = patch(NaN, NaN, colors(i,:), ...
                             'FaceAlpha', 0.2, ...
                             'EdgeColor', 'none', ...
                             'Parent', axMain);
end

legend(axMain, legendHandles, groupNames, ...
       'Location', 'northwest', ...
       'FontSize', baseFontSize - 4);
