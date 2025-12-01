% ----------------- 参数设置 -----------------
fs         = 1000;            % 采样率 (Hz)
thetaBand  = [4 8];           % θ 频段 (Hz)
gammaBand  = [30 50];         % γ 频段 (Hz)
nBins      = 18;              % 相位分箱数

% data_pre_risk 已在工作区，尺寸 5000×8
[nSamples, nCh] = size(data_pre_risk);

% 取前 8 色调色板（Nature 风格）
colors12 = [
    0.82 0.28 0.36;  0.28 0.47 0.82;  0.00 0.64 0.54;  0.90 0.60 0.16;
    0.57 0.42 0.65;  0.35 0.64 0.82;  0.60 0.60 0.60;  0.88 0.49 0.62;
];
colors = colors12(1:nCh, :);

% 滤波器设计
[bTh,aTh] = butter(2, thetaBand./(fs/2), 'bandpass');
[bGa,aGa] = butter(2, gammaBand./(fs/2), 'bandpass');

% ----------- 计算 PAC & MI (180° 峰值对齐) -----------
edgesDeg   = linspace(0,360,nBins+1);
edgesRad   = deg2rad(edgesDeg);
binCenters = (edgesDeg(1:end-1) + diff(edgesDeg)/2);
targetDeg  = 180;
[~, targetBin] = min(abs(binCenters - targetDeg));

Pmat = zeros(nCh, nBins);
MI   = nan(nCh,1);     % 先设为 NaN，方便跳过
for ic = 1:nCh
    seg = data_pre_risk(:, ic);

    % --- 滤波 & 包络 ---
    th  = filtfilt(bTh, aTh, seg);
    ga  = filtfilt(bGa, aGa, seg);
    amp = abs(hilbert(ga));

    %% --- NEW --- %%  峰显著度过滤 & 跳过逻辑
    [~,~,~,proms] = findpeaks(amp);
    if isempty(proms)        % 没有峰，直接跳过
        warning('Channel %d skipped: no peaks found.', ic);
        Pmat(ic,:) = 0;      % 绘图保持格式
        continue
    end
    mainMask = proms >= 0.5*max(proms);
    if sum(mainMask) < numel(proms)   % 存在小峰 → 跳过
        warning('Channel %d skipped: minor peaks detected.', ic);
        Pmat(ic,:) = 0;
        continue
    end
    %% --- NEW END --- %%

    % ---------- PAC 统计 ----------
    phi = angle(hilbert(th)) + pi;         % [0,2π)
    phi(phi>pi) = phi(phi>pi) - 2*pi;      % (-π,π]
    deg = rad2deg(phi);
    deg(deg<0) = deg(deg<0) + 360;         % [0,360)

    P = zeros(1,nBins);
    for b = 1:nBins
        idx = deg>=edgesDeg(b) & deg<edgesDeg(b+1);
        P(b) = mean(amp(idx));
    end
    P = P / sum(P);

    H    = -sum(P .* log(P + eps));
    Hmax = log(nBins);
    MI(ic) = (Hmax - H) / Hmax;

    [~, maxBin] = max(P);
    Pmat(ic,:)  = circshift(P, [0, targetBin-maxBin]);
end
avgMI = mean(MI,'omitnan');   % 略过 NaN 通道

% ------------- 绘图 (Cartesian + patch) -------------
set(0,'defaultfigurecolor','w');
figure('Position',[200 100 1800 1200]);
ax = axes; hold(ax,'on'); axis(ax,'equal'); axis(ax,'off');

% 固定最大半径为 0.09
outerR    = 0.09;
thetaGrid = linspace(0,2*pi,300);

% 绘制扇区柱
for ic = 1:nCh
    col = colors(ic,:);
    for k = 1:nBins
        th1 = edgesRad(k);
        th2 = edgesRad(k+1);
        r1  = 0;
        r2  = Pmat(ic,k);           % 若跳过→0，不影响绘图结构
        [x1,y1] = pol2cart(th1, r1);
        [x2,y2] = pol2cart(th1, r2);
        [x3,y3] = pol2cart(th2, r2);
        [x4,y4] = pol2cart(th2, r1);
        patch(ax,[x1 x2 x3 x4],[y1 y2 y3 y4],col,...
              'FaceAlpha',0.4,'EdgeColor',col,'LineWidth',2,...
              'HandleVisibility','off');
    end
end

% 绘制极网格：0.02、0.06、0.09
gridR = [0.02 0.06 outerR];
for r = gridR
    [xg,yg] = pol2cart(thetaGrid, r);
    plot(ax,xg,yg,'Color',[0.7 0.7 0.7],'LineWidth',2);
end
% 外圈粗线
[xo,yo] = pol2cart(thetaGrid, outerR);
plot(ax,xo,yo,'k','LineWidth',5);
% 径向线
for degA = 0:30:330
    [xg,yg] = pol2cart(deg2rad(degA),[0 outerR]);
    plot(ax,xg,yg,'Color',[0.8 0.8 0.8],'LineWidth',2);
end

% 角度标签
labelR = outerR*1.05;
text(ax, labelR, 0,    '0°',   'HorizontalAlignment','center','FontSize',18);
text(ax, 0,      labelR,'90°', 'HorizontalAlignment','center','FontSize',18);
text(ax,-labelR, 0,    '180°','HorizontalAlignment','center','FontSize',18);
text(ax, 0,     -labelR,'270°','HorizontalAlignment','center','FontSize',18);

% 内圈半径数值
for r = gridR(1:2)           % 0.02, 0.06
    [xr,yr] = pol2cart(pi/2, r);
    text(ax,xr,yr,sprintf('%.2f',r),'HorizontalAlignment','center',...
         'VerticalAlignment','bottom','FontSize',14);
end
% 最外圈 0.09
[xoLab,yoLab] = pol2cart(pi/2, outerR);
text(ax,xoLab,yoLab,sprintf('%.2f',outerR),'HorizontalAlignment','center',...
     'VerticalAlignment','bottom','FontSize',14);

% 图例
legH = gobjects(nCh,1);
for ic = 1:nCh
    legH(ic) = plot(ax,NaN,NaN,'-','Color',colors(ic,:),'LineWidth',4);
end
lg = legend(legH, arrayfun(@(x) sprintf('Trial%d',x),1:nCh,'UniformOutput',false),...
            'Location','eastoutside','FontSize',14);
lg.Box='on'; lg.LineWidth=3; lg.Units='normalized';
pos = lg.Position; pos(1)=pos(1)+0.05; pos(3)=pos(3)*1.3; pos(4)=pos(4)*1.3; lg.Position = pos;

t = title(ax,'Pre-RISK','FontSize',40);
t.Units='normalized'; t.HorizontalAlignment='center'; t.Position=[0.5,1.02,0];

% ---------- 输出 MI ----------
fprintf('\nModulation Index per channel (data_pre_risk)\n');
for ic = 1:nCh
    if isnan(MI(ic))
        fprintf('Trial%-2d : SKIPPED\n', ic);
    else
        fprintf('Trial%-2d : %.4f\n', ic, MI(ic));
    end
end
