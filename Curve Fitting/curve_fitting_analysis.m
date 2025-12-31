clear; close all; clc;

%% 1. Data Import and Cleaning
data = readmatrix('data_to_curve_fit.txt');
x = data(:,1);
y = data(:,2);

% Remove invalid values
valid = ~(isnan(x) | isnan(y) | isinf(x) | isinf(y));
x = x(valid);
y = y(valid);

% Remove duplicate x values
[unique_x, ia, ~] = unique(x, 'stable');
x = unique_x;
y = y(ia);

% Ensure column vectors and sorted
[x, sidx] = sort(x);
y = y(sidx);

fprintf('Data cleaned successfully\n');
fprintf('Number of data points: %d\n', length(x));
fprintf('X range: [%.2f, %.2f]\n', min(x), max(x));
fprintf('Y range: [%.2f, %.2f]\n\n', min(y), max(y));

%% 2. Initial Plot
fig1 = figure('Position',[100 100 1400 360]);
subplot(1,4,1);
plot(x, y, 'b.', 'MarkerSize', 3);
grid on; title('Original Data'); xlabel('x'); ylabel('y');

%% 3. OPTIMAL Breakpoint Strategy - I will use Many Uniform Breakpoints
% For highly oscillatory data, uniform spacing works better than curvature
fprintf('Computing optimal breakpoint distribution:\n');

% My Strategy: Use MANY evenly-spaced breakpoints
% This will allows the spline to adapt locally to oscillations
n_breakpoints = 30;  

% Create uniform breakpoints
breakpoints = linspace(min(x), max(x), n_breakpoints)';

num_segments = length(breakpoints) - 1;
fprintf('Number of breakpoints: %d\n', n_breakpoints);
fprintf('Number of spline segments: %d\n', num_segments);
fprintf('Average segment width: %.2f\n\n', mean(diff(breakpoints)));

% Calculate and plot curvature for reference
dx = gradient(x);
dy = gradient(y);
d1 = dy ./ dx;                  
d2 = gradient(d1) ./ dx;        
curv = abs(d2);
window = max(3, round(length(curv)/300));
curv_smooth = movmedian(curv, window);

subplot(1,4,2);
plot(x, curv_smooth, '-', 'LineWidth', 1.5, 'Color', 'b'); hold on;
for k = 2:length(breakpoints)-1
    xline(breakpoints(k), 'g--', 'LineWidth', 0.5, 'Alpha', 0.3);
end
grid on; title('Curvature & Breakpoints'); xlabel('x'); ylabel('|d²y/dx²|');

%% 4. Enhanced Spline Fitting with High-Order Splines
y_fit = nan(size(y));
method_used = '';

fprintf('Fitting spline with optimized parameters:\n');

try
    % I will use spap2 with cubic splines (order 4) and many breakpoints
    % This gives excellent local adaptation
    sp = spap2(breakpoints, 4, x, y);
    y_fit = fnval(sp, x);
    method_used = sprintf('spap2 (Cubic spline, %d segments)', num_segments);
    fprintf('Primary method successful\n\n');
    
catch ME1
    fprintf('Primary method failed: %s\n', ME1.message);
    fprintf('Trying fallback method\n');
    
    try
        % Fallback: Very high tolerance smoothing spline
        p = 1e-10;  
        y_fit = csaps(x, y, p, x);
        method_used = sprintf('csaps (Smoothing spline, p=%.0e)', p);
        fprintf('Fallback method successful\n\n');
        
    catch ME2
        % Final fallback: Curve fitting toolbox
        fit_model = fit(x, y, 'smoothingspline', 'SmoothingParam', 0.001);
        y_fit = feval(fit_model, x);
        method_used = 'fit() smoothing spline';
        fprintf('Final fallback successful\n\n');
    end
end

fprintf('Fitting method: %s\n\n', method_used);

%% 5. Calculate KPIs
if any(isnan(y_fit)) || any(isinf(y_fit))
    error('Fitting produced invalid values (NaN or Inf)');
end

residuals = y - y_fit;
SE = sum(residuals.^2);
RMSE = sqrt(SE / length(y));
norm_2 = norm(residuals);
R_squared = 1 - SE / sum((y - mean(y)).^2);

fprintf('========================================\n');
fprintf('KEY PERFORMANCE INDICATORS (KPIs)\n');
fprintf('========================================\n');
fprintf('2-Norm of Residuals : %.4f\n', norm_2);
fprintf('Squared Error (SE)  : %.4e\n', SE);
fprintf('RMSE                : %.4f\n', RMSE);
fprintf('R-squared           : %.6f\n', R_squared);
fprintf('========================================\n\n');

%% 6. Comprehensive Quality Assessment
fprintf('========================================\n');
fprintf('FIT QUALITY ASSESSMENT\n');
fprintf('========================================\n');

% R-squared assessment
if R_squared > 0.95
    fprintf('EXCELLENT fit (R² = %.4f > 0.95)\n', R_squared);
elseif R_squared > 0.90
    fprintf('GOOD fit (R² = %.4f > 0.90)\n', R_squared);
elseif R_squared > 0.80
    fprintf('ACCEPTABLE fit (R² = %.4f > 0.80)\n', R_squared);
elseif R_squared > 0.70
    fprintf('MODERATE fit (R² = %.4f)\n', R_squared);
else
    fprintf('POOR fit (R² = %.4f < 0.70)\n', R_squared);
end

% Relative RMSE
relative_rmse = RMSE / (max(y) - min(y)) * 100;
fprintf('Relative RMSE: %.2f%% of data range', relative_rmse);
if relative_rmse < 5
    fprintf(' - "Excellent"\n');
elseif relative_rmse < 10
    fprintf(' - "Good"\n');
elseif relative_rmse < 15
    fprintf(' - "Acceptable"\n');
else
    fprintf(' - "Poor"\n');
end

% Bias assessment
bias_ratio = abs(mean(residuals)) / RMSE;
fprintf('Bias ratio: %.4f', bias_ratio);
if bias_ratio < 0.05
    fprintf(' - "No systematic bias"\n');
elseif bias_ratio < 0.1
    fprintf(' - "Minor bias"\n');
else
    fprintf(' - "Significant bias detected"\n');
end

% Residual normality (I think should be roughly normally distributed)
residuals_normalized = (residuals - mean(residuals)) / std(residuals);
within_2sigma = sum(abs(residuals_normalized) <= 2) / length(residuals) * 100;
fprintf('Points within ±2σ: %.1f%%', within_2sigma);
if within_2sigma > 93
    fprintf(' - Good (expect ~95%%)\n');
else
    fprintf(' - Check for outliers\n');
end
fprintf('========================================\n\n');

%% 7. Visualizations
subplot(1,4,3);
plot(x, y, 'b.', 'MarkerSize', 3); hold on;
plot(x, y_fit, 'r-', 'LineWidth', 1.8);
% I will Show only a few breakpoints to avoid clutter
for k = 1:5:length(breakpoints)
    xline(breakpoints(k), 'g--', 'LineWidth', 0.5, 'Alpha', 0.3);
end
grid on; title('Fitted Curve'); xlabel('x'); ylabel('y');
legend('Data', 'Spline Fit', 'Location', 'best');

subplot(1,4,4);
plot(x, residuals, 'k.', 'MarkerSize', 3); hold on;
yline(0, 'r--', 'LineWidth', 1.5);
yline(mean(residuals), 'b--', 'LineWidth', 1);
yline(2*std(residuals), 'm:', 'LineWidth', 1);
yline(-2*std(residuals), 'm:', 'LineWidth', 1);
grid on; title('Residuals'); xlabel('x'); ylabel('Residual');

% Detailed figure
fig2 = figure('Position',[100 100 1200 800]);

% Main plot
subplot(2,2,1:2);
plot(x, y, 'b.', 'MarkerSize', 4, 'DisplayName', 'Measured Data'); hold on;
plot(x, y_fit, 'r-', 'LineWidth', 2.2, 'DisplayName', 'Spline Fit');
% Show breakpoints every 5th one
for k = 1:5:length(breakpoints)
    if k == 1
        xline(breakpoints(k), 'g--', 'LineWidth', 0.8, 'Alpha', 0.4, ...
               'DisplayName', 'Breakpoints (every 5th)');
    else
        xline(breakpoints(k), 'g--', 'LineWidth', 0.8, 'Alpha', 0.4, ...
               'HandleVisibility', 'off');
    end
end
grid on; 
title(sprintf('Curve Fitting Results: %s (R² = %.4f)', method_used, R_squared), ...
      'FontSize', 12, 'FontWeight', 'bold');
xlabel('Independent Variable (x)', 'FontSize', 11, 'FontWeight', 'bold');
ylabel('Dependent Variable (y)', 'FontSize', 11, 'FontWeight', 'bold');
legend('Location', 'northwest');

% Residual plot
subplot(2,2,3);
plot(x, residuals, 'ko', 'MarkerSize', 3, 'MarkerFaceColor','k');
hold on; 
yline(0, 'r-', 'LineWidth', 1.5, 'DisplayName', 'Zero'); 
yline(mean(residuals), 'b--', 'LineWidth', 1.5, ...
      'DisplayName', sprintf('Mean=%.2e', mean(residuals)));
yline(2*std(residuals), 'm:', 'LineWidth', 1.5, 'DisplayName', '±2σ');
yline(-2*std(residuals), 'm:', 'LineWidth', 1.5, 'HandleVisibility', 'off');
grid on; 
title('Residual Distribution', 'FontSize', 12, 'FontWeight', 'bold');
xlabel('x'); ylabel('Residual');
legend('Location', 'best');

% Histogram with normal distribution overlay
subplot(2,2,4);
histogram(residuals, 50, 'Normalization', 'pdf', ...
          'FaceColor', [0.3, 0.6, 0.8], 'EdgeColor', 'k');
hold on;
% Fit normal distribution
mu = mean(residuals);
sigma = std(residuals);
x_norm = linspace(min(residuals), max(residuals), 100);
y_norm = normpdf(x_norm, mu, sigma);
plot(x_norm, y_norm, 'r-', 'LineWidth', 2, 'DisplayName', 'Normal fit');
grid on; 
title('Residual Histogram vs Normal', 'FontSize', 12, 'FontWeight', 'bold');
xlabel('Residual Value'); ylabel('Probability Density');
legend('Location', 'best');

%% 8. Statistical Summary
fprintf('========================================\n');
fprintf('STATISTICAL SUMMARY\n');
fprintf('========================================\n');
fprintf('Mean of residuals   : %.4e (bias indicator)\n', mean(residuals));
fprintf('Std deviation       : %.4f\n', std(residuals));
fprintf('Min residual        : %.4f\n', min(residuals));
fprintf('Max residual        : %.4f\n', max(residuals));
fprintf('Max abs residual    : %.4f\n', max(abs(residuals)));
fprintf('Median abs residual : %.4f\n', median(abs(residuals)));
fprintf('========================================\n\n');

%% 9. Model Information Summary
fprintf('========================================\n');
fprintf('MODEL INFORMATION\n');
fprintf('========================================\n');
fprintf('Fitting method      : %s\n', method_used);
fprintf('Number of segments  : %d\n', num_segments);
fprintf('Points per segment  : ~%d\n', round(length(x)/num_segments));
fprintf('Breakpoint spacing  : %.2f (mean)\n', mean(diff(breakpoints)));
fprintf('========================================\n\n');

%% 10. Save Results
fprintf('Saving results.\n');

% Save figures
saveas(fig1, 'curve_fitting_overview.png');
saveas(fig2, 'curve_fitting_detailed.png');
fprintf('Fig-1&2 Saved Successfully\n');

% Save data table
results_table = table(x, y, y_fit, residuals, ...
    'VariableNames', {'X','Y_Original','Y_Fitted','Residuals'});
writetable(results_table, 'fitting_results.xlsx');
fprintf('Saved: fitting_results.xlsx\n');

fprintf('YES : DONE WE ARE FINISHED');

