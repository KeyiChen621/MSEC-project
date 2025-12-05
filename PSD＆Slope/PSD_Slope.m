%% ====================== Global Parameters ======================
fs        = 1000;                   % Sampling rate (Hz)
win       = 1000;                   % Welch window length (1 s)
overlap   = win/2;                  % 50% overlap
nfft      = 2048;                   % Number of FFT points
f_range   = [30 70];                % Frequency range for zoom-in & slope fitting (Hz)

states     = {'pre','beginner','practicer','expert'};     % Learning states
stateNames = {'Pre','Beginner','Practicer','Expert'};     % Names for legend display

% Single experimental group used in this analysis
groups = {'risk'};

colors = lines(4);                  % Colormap for the 4 learning states

axisLineWidth = 1.5;                % Axis line width
baseFontSize  = 20;                 % Font size for all text

% Store the slopes of the 1/f fit across states
slopes = struct('risk', nan(1,4));

% Power-line harmonic notch filter frequencies
notchFreqs = [50, 150, 250];

% Q-factor settings for each behavioral state
Qs_map.pre.risk       = [1000, 1000, 1000];
Qs_map.beginner.risk  = [100,  300,  500];
Qs_map.practicer.risk = [100,  300,  500];
Qs_map.expert.risk    = [100,  300,  500];

%% ====================== Main Loop ======================
for gi = 1:numel(groups)
    grp = groups{gi};
    
    % Create main figure
    hFig   = figure('Position',[100 100 900 800]);
    axMain = axes('Parent',hFig); 
    hold(axMain,'on');
    set(axMain, ...
        'Box','on', ...
        'LineWidth',axisLineWidth, ...
        'FontSize',baseFontSize, ...
        'FontWeight','bold');
    
    % Containers for the inset plot
    f_all       = [];
    mPdB_all    = cell(4,1);
    ci95_all    = cell(4,1);
    f_fit_all   = cell(4,1);
    Pfit_dB_all = cell(4,1);

    %% ==== Loop across all learning states ====
    for si = 1:numel(states)
        state   = states{si};

        % Load data matrix (size: 5000 × 8)
        dataMat = eval(sprintf('data_%s_%s', state, grp));
        
        %% ----- Multi-band notch filtering -----
        Qs = Qs_map.(state).(grp);
        clear bNotch aNotch
        for k = 1:numel(notchFreqs)
            w0 = notchFreqs(k)/(fs/2);     % Normalized frequency
            bw = w0 / Qs(k);               % Bandwidth determined by Q-factor
            [bNotch{k}, aNotch{k}] = iirnotch(w0, bw);
        end
        
        % Apply all notch filters
        dataFilt = dataMat;
        for k = 1:numel(notchFreqs)
            dataFilt = filtfilt(bNotch{k}, aNotch{k}, dataFilt);
        end
        
        %% ----- Compute PSD using Welch's method -----
        [pxx, f] = pwelch(dataFilt, win, overlap, nfft, fs);
        idx300   = f <= 300;
        f_use    = f(idx300);
        pxx_use  = pxx(idx300,:);
        
        %% ----- Convert to dB and compute 95% CI -----
        pxx_dB = 10*log10(pxx_use);
        mPdB   = mean(pxx_dB,2);
        semPdB = std(pxx_dB,0,2) ./ sqrt(size(pxx_dB,2));
        ci95   = 1.96 * semPdB;
        
        %% ----- Plot PSD with shaded 95% CI -----
        fill([f_use; flipud(f_use)], ...
             [mPdB+ci95; flipud(mPdB-ci95)], ...
             colors(si,:), 'FaceAlpha',0.2, 'EdgeColor','none', 'Parent',axMain);
        
        plot(axMain, f_use, mPdB, 'Color',colors(si,:), 'LineWidth',2);
        
        %% ----- Fit slope on log-log PSD (30–70 Hz except 48–52 Hz) -----
        idxFit = (f_use>=f_range(1) & f_use<=f_range(2)) & ...
                 ~(f_use>=48 & f_use<=52);
        logF = log10(f_use(idxFit));
        logP = log10(mean(pxx_use(idxFit,:),2));
        
        coeffs = robustfit(logF, logP);
        slopes.(grp)(si) = coeffs(2);   % Slope term
        
        % Compute predicted fit and convert to dB
        P_pred_lin      = 10.^(coeffs(1) + coeffs(2)*logF);
        Pfit_dB_all{si} = 10*log10(P_pred_lin);
        f_fit_all{si}   = f_use(idxFit);
        
        plot(axMain, f_fit_all{si}, Pfit_dB_all{si}, '--', ...
             'Color',colors(si,:), 'LineWidth',2);

        %% Store values for inset
        if isempty(f_all), f_all = f_use; end
        mPdB_all{si} = mPdB;
        ci95_all{si} = ci95;
    end
    
    %% ====================== Main Plot Formatting ======================
    xlim(axMain,[0 300]);
    xlabel(axMain,'Frequency (Hz)', 'FontSize',baseFontSize,'FontWeight','bold');
    ylabel(axMain,'PSD (dB/Hz)',   'FontSize',baseFontSize,'FontWeight','bold');

    % Zoom-in region boundaries
    idxZoom = f_all>=f_range(1) & f_all<=f_range(2);
    yMin = min(cellfun(@(m,c) min(m(idxZoom)-c(idxZoom)), mPdB_all, ci95_all));
    yMax = max(cellfun(@(m,c) max(m(idxZoom)+c(idxZoom)), mPdB_all, ci95_all));

    rectangle(axMain, 'Position',[f_range(1), yMin, diff(f_range), yMax-yMin], ...
              'EdgeColor','k','LineStyle','--','LineWidth',2);

    %% ----- Custom Legend -----
    legendHandles = gobjects(4,1);
    for si = 1:4
        legendHandles(si) = patch([0 1 1 0],[0 0 1 1], colors(si,:), ...
                                  'FaceAlpha',0.2,'EdgeColor','none','Parent',axMain);
    end
    legend(axMain, legendHandles, stateNames, 'Location','southwest', ...
           'FontSize',baseFontSize-1);

    %% ====================== Inset Plot (Zoom-in) ======================
    insetPos = [0.45 0.45 0.35 0.35];
    axInset = axes('Parent',hFig,'Position',insetPos);
    hold(axInset,'on'); 
    box(axInset,'on');
    
    % Generate Y-ticks with integer spacing
    numTicks = 6;
    minTick  = floor(yMin);
    maxTick  = ceil (yMax);
    tickStep = ceil((maxTick - minTick)/(numTicks-1));
    yTicks   = minTick : tickStep : (minTick + tickStep*(numTicks-1));
    
    if numel(yTicks)>numTicks
        yTicks = yTicks(1:numTicks);
    elseif numel(yTicks)<numTicks
        yTicks = [yTicks, yTicks(end)+tickStep*(1:(numTicks-numel(yTicks)))];
    end

    set(axInset, ...
        'LineWidth',axisLineWidth, ...
        'FontSize',baseFontSize, ...
        'FontWeight','bold', ...
        'XTick',[30 40 50 60 70], ...
        'YTick',yTicks);

    axInset.YAxis.TickLabelFormat = '%.0f';  % Force integer tick labels

    % Plot inset curves
    for si = 1:4
        fill([f_all(idxZoom); flipud(f_all(idxZoom))], ...
             [mPdB_all{si}(idxZoom)+ci95_all{si}(idxZoom); ...
              flipud(mPdB_all{si}(idxZoom)-ci95_all{si}(idxZoom))], ...
             colors(si,:), 'FaceAlpha',0.2,'EdgeColor','none','Parent',axInset);
        plot(axInset, f_all(idxZoom), mPdB_all{si}(idxZoom), ...
             'Color',colors(si,:),'LineWidth',2);
        plot(axInset, f_fit_all{si}, Pfit_dB_all{si}, '--', ...
             'Color',colors(si,:),'LineWidth',2);
    end

    xlim(axInset, f_range);
    ylim(axInset, [yMin yMax]);

    %% Display fitted slope values
    text(axMain, 0.02, 0.92, ...
         sprintf('Slopes: pre=%.3f  beg=%.3f  prac=%.3f  exp=%.3f', slopes.(grp)), ...
         'Units','normalized','FontSize',baseFontSize-1,'FontWeight','bold');

    fprintf('Slopes for %s group: pre=%.3f, beginner=%.3f, practicer=%.3f, expert=%.3f\n', ...
        grp, slopes.(grp)(1), slopes.(grp)(2), slopes.(grp)(3), slopes.(grp)(4));
end
