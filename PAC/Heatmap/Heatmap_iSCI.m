% ===========================================================
% PAC_heatmap_selectedGroups_labeled.m
% Use selectedGroups (nGroups × nPerGroup cell array, each 5000×1 segment)
% to compute phase–amplitude coupling (PAC) and plot a 112×720° heatmap
% with trial/day labels.
% ===========================================================

%% -------- Parameter settings --------
fs            = 1000;            % Sampling rate (Hz)
thetaBand     = [6 10];          % Theta band (Hz)
gammaBand     = [30 50];         % Gamma band (Hz)
nBins360      = 18;              % Number of bins over 0–360° → 20°/bin
dPhase        = 360 / nBins360;  % Bin width (degrees)
binCenters360 = (0:nBins360-1) * dPhase;   % [0, 20, 40, …, 340]

targetDeg     = 180;             % Target phase (for peak alignment)
[~, targetBin] = min(abs(binCenters360 - targetDeg));

% Band-pass filters for theta and gamma
[bTh, aTh] = butter(2, thetaBand./(fs/2), 'bandpass');
[bGa, aGa] = butter(2, gammaBand./(fs/2), 'bandpass');

% selectedGroups is an nGroups × nPerGroup cell array in the workspace
% Each cell contains one 5000×1 time series segment
[nGroups, nPerGroup] = size(selectedGroups);
nTrials = nGroups * nPerGroup;

% Preallocate: one row per segment (trial), one column per phase bin
P360_all = zeros(nTrials, nBins360);

%% -------- Compute P(phase) and align peaks --------
row = 0;
for g = 1:nGroups
    for k = 1:nPerGroup
        row = row + 1;
        x = selectedGroups{g, k};    % 5000×1 data segment
        
        % Theta and gamma filtering + Hilbert transform
        th = filtfilt(bTh, aTh, x);
        ga = filtfilt(bGa, aGa, x);
        
        % Extract theta phase and map it to [0, 360)
        phi = angle(hilbert(th)) + pi;
        phi(phi > pi) = phi(phi > pi) - 2*pi;
        deg = rad2deg(phi);
        deg(deg < 0) = deg(deg < 0) + 360;
        
        % Extract gamma amplitude envelope
        ampEnv = abs(hilbert(ga));
        
        % Bin by phase and compute mean amplitude
        edges = 0:dPhase:360;
        P = zeros(1, nBins360);
        for b = 1:nBins360
            idx = deg >= edges(b) & deg < edges(b+1);
            P(b) = mean(ampEnv(idx));
        end
        
        % Normalize to obtain a probability-like distribution over phase
        P = P / sum(P);
        
        % Peak alignment: shift so the maximum bin is at targetBin
        [~, maxBin] = max(P);
        shiftAmt    = targetBin - maxBin;
        P_aligned   = circshift(P, [0, shiftAmt]);
        
        % Store in matrix (one row per trial)
        P360_all(row, :) = P_aligned;
    end
end

%% -------- Extend from 0–360° to 0–720° and close the cycle at 720° --------
P720          = [P360_all, P360_all, P360_all(:,1)];   % Append first column as 720°
binCenters720 = [binCenters360, binCenters360 + 360, 720];

%% -------- Plot PAC heatmap --------
figure('Color','w');
imagesc(binCenters720, 1:nTrials, P720);
axis ij;                % Put Trial 1 at the top

% Y-axis tick positions: one label per group (day)
yticks = (1:nGroups) * nPerGroup - nPerGroup/2;

% Generate day labels and hide even-numbered days
ylabels = arrayfun(@(d) num2str(d), 1:nGroups, 'UniformOutput', false);


set(gca, ...
    'Box',        'on', ...
    'LineWidth',  1.5, ...            % Axis/frame and tick line width
    'TickDir',    'in', ...
    'XLim',       [0 720], ...
    'FontWeight', 'bold', ...         % Bold tick labels
    'FontSize',   20, ...
    'XTick',      [0 180 360 540 720], ...
    'YTick',      yticks, ...
    'YTickLabel', ylabels ...
);

xlabel('Theta Phase (°)',          'FontWeight','bold', 'FontSize',20);
ylabel('Training Day',             'FontWeight','bold', 'FontSize',20);
title('LG Amplitude vs Theta Phase','FontWeight','bold', 'FontSize',20);

%% -------- Colormap (RdBu, inverted) --------
cmap = brewermap(256, 'RdBu');
cmap = flipud(cmap);
colormap(cmap);

cb = colorbar('Location','eastoutside');
cb.Label.String   = 'Normalized Gamma Amplitude';
cb.LineWidth      = 1.5;       % Thicker colorbar border and ticks
cb.TickLength     = 0.01;      % Optional: adjust tick length
cb.TickDirection  = 'in';      % Optional: ticks pointing inward

%% -------- Draw horizontal separators between groups --------
hold on;
for g = 1:(nGroups-1)
    yline(g*nPerGroup + 0.5, 'Color',[0.5 0.5 0.5], 'LineStyle','--');
end
hold off;
