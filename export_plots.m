% export_plots.m
% Export all MATLAB pipeline figures to assets/plots/ for the portfolio README.
%
% Usage (from repo root):
%   matlab -batch "run('run_project.m'); run('export_plots.m')"
%
% Output: assets/plots/<FigureName>.png  (150 dpi, white background)

repoRoot  = pwd;
assetsDir = fullfile(repoRoot, 'assets', 'plots');
if ~exist(assetsDir, 'dir'); mkdir(assetsDir); end

fprintf('=== export_plots: running main.m (figures hidden) ===\n');
set(0, 'DefaultFigureVisible', 'off');
run('main.m');
set(0, 'DefaultFigureVisible', 'on');

% main.m runs `clear` internally — redefine after the run
repoRoot  = pwd;
assetsDir = fullfile(repoRoot, 'assets', 'plots');
if ~exist(assetsDir, 'dir'); mkdir(assetsDir); end

figs = findall(0, 'type', 'figure');
fprintf('Found %d figures. Saving to assets/plots/\n', numel(figs));

for k = 1:numel(figs)
    fig  = figs(k);
    name = get(fig, 'Name');
    if isempty(name)
        name = sprintf('figure_%d', k);
    end
    fname = regexprep(name, '[^a-zA-Z0-9 \-_]', '');
    fname = strtrim(fname);
    fname = strrep(fname, ' ', '_');
    fname = regexprep(fname, '_+', '_');

    outPath = fullfile(assetsDir, [fname '.png']);
    try
        exportgraphics(fig, outPath, 'Resolution', 150, 'BackgroundColor', 'white');
        fprintf('  [OK] %s\n', fname);
    catch ME
        fprintf('  [FAIL] %s — %s\n', fname, ME.message);
    end
end

close all;
fprintf('\nDone. %d figures saved to assets/plots/\n', numel(figs));
fprintf('Commit assets/plots/ and assets/images/ to see them on GitHub.\n');
