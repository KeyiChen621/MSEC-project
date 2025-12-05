%% ----------------- Parameter settings -----------------
fs        = 1000;          % Sampling rate (Hz)
thetaBand = [4 8];         % Theta band (Hz)
gammaBand = [30 50];       % Gamma band (Hz)
nBins     = 18;            % Number of phase bins over 0–360°

% data_expert_risk is assumed to exist in the workspace, size 5000 × 8
[nSamples, nCh] = size(data_expert_risk);

% Color map for up to 8 channels/trials
colors12 = [
    0.82 0.28 0.36;
    0.28 0.47 0.82;
    0.00 0.64 0.54;
    0.90 0.60 0.16;
    0.57 0.42 0.65;
    0.35 0.64 0.82;
    0.60 0.60 0.60;
    0.88 0.49 0.62;
];
colors = colors12(1:nCh, :);

% Band-pass filters for theta and gamma
[bTh, aTh] = butter(2, thetaBand./(fs/2), 'bandpass');
[bGa, aGa] = butter(2, gammaBand./(fs/2), 'bandpass');

%% ----------- Compute PAC & MI (peak aligned at 180°) -----------
edgesDeg   = linspace(0, 360, nBins+1);         % Bin edges in degrees
edgesRad   = deg2rad(edgesDeg);                 % Bin edges in radians
binCenters = (edgesDeg(1:end-1) + diff(edgesDeg)/2);  % Bin centers (deg)

targetDeg  = 180;                               % Target phase for alignment
[~, targetBin] = min(abs(binCenters - targetDeg));

Pmat = zeros(nCh, nBins);   % Phase–amplitude distributions per channel
MI   = zeros(nCh, 1);       % Modulation index per channel

for ic = 1:nCh
    seg = data_expert_risk(:, ic);
    
    % Theta and gamma filtering
    th = filtfilt(bTh, aTh, seg);
    ga = filtfilt(bGa, aGa, seg);
    
    % Theta phase in [0, 360)
    phi = angle(hilbert(th)) + pi;
    phi(phi > pi) = phi(phi > pi) - 2*pi;
    deg = rad2deg(phi);
    deg(deg < 0) = deg(deg < 0) + 360;
    
    % Gamma amplitude envelope
    amp = abs(hilbert(ga));
    
    % Bin by phase and compute mean gamma amplitude
    P = zeros(1, nBins);
    for b = 1:nBins
        idx = deg >= edgesDeg(b) & deg < edgesDeg(b+1);
        P(b) = mean(amp(idx));
    end
    
    % Normalize to obtain a phase distribution
    P = P / sum(P);
    
    % Modulation index (Tort et al. 2010 style)
    H    = -sum(P .* log(P + eps));   % Shannon entropy
    Hmax = log(nBins);
    MI(ic) = (Hmax - H) / Hmax;
    
    % Peak alignment: shift so the maximum bin is at targetBin (≈180°)
    [~, maxBin] = max(P);
    Pmat(ic, :) = circshift(P, [0, targetBin - maxBin]);
end

avgMI = mean(MI);  %#ok<NASGU>  % Average MI across channels (if needed)

%% ------------- Plotting in Cartesian coordinates (patch) -------------
set(0, 'DefaultFigureColor', 'w');
figure('Position', [200 100 1800 1200]);
ax = axes;
hold(ax, 'on');
axis(ax, 'equal');
axis(ax, 'off');

% Fixed outer radius (for scaling the polar bars)
outerR    = 0.09;
thetaGrid = linspace(0, 2*pi, 300);

% Draw phase–amplitude bars
for ic = 1:nCh
    col = colors(ic, :);
    for k = 1:nBins
        th1 = edgesRad(k);
        th2 = edgesRad(k+1);
        r1  = 0;
        r2  = Pmat(ic, k);
        
        [x1, y1] = pol2cart(th1, r1);
        [x2, y2] = pol2cart(th1, r2);
        [x3, y3] = pol2cart(th2, r2);
        [x4, y4] = pol2cart(th2, r1);
        
        patch(ax, [x1 x2 x3 x4], [y1 y2 y3 y4], col, ...
              'FaceAlpha', 0.4, ...
              'EdgeColor', col, ...
              'LineWidth', 2, ...
              'HandleVisibility', 'off');
    end
end

% Concentric radial grid at r = 0.02, 0.06, outerR
gridR = [0.02, 0.06, outerR];
for r = gridR
    [xg, yg] = pol2cart(thetaGrid, r);
    plot(ax, xg, yg, 'Color', [0.7 0.7 0.7], 'LineWidth', 2);
end

% Outer circle (thicker line)
[xo, yo] = pol2cart(thetaGrid, outerR);
plot(ax, xo, yo, 'k', 'LineWidth', 5);

% Radial lines every 30°
for degA = 0:30:330
    [xg, yg] = pol2cart(deg2rad(degA), [0 outerR]);
    plot(ax, xg, yg, 'Color', [0.8 0.8 0.8], 'LineWidth', 2);
end

%% ------------- Print MI values -------------
fprintf('\nModulation Index per channel (data_expert_risk)\n');
for ic = 1:nCh
    fprintf('Trial %-2d : %.4f\n', ic, MI(ic));
end
