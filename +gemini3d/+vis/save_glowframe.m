function save_glowframe(h, filename, saveplot_fmt)
%% CREATES IMAGE FILES FROM PLOTS
arguments
  h (1,1) matlab.ui.Figure
  filename (1,1) string
  saveplot_fmt (1,:) string
end

dpi = '150';

[outdir, outname] = fileparts(filename);
outdir = fullfile(outdir, "../plots");

saveplot_fmt(~strlength(saveplot_fmt)) = [];

for suffix = saveplot_fmt
  outfile = fullfile(outdir, "aurora-" + outname + "." + suffix);
  disp("write " + outfile)
  gemini3d.vis.export_graphics(h, outfile, 'resolution', dpi)
end

end % function
