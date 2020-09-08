function plotframe(direc, time_req, saveplot_fmt, options)
%% CHECK ARGS AND SET SOME DEFAULT VALUES ON OPTIONAL ARGS
arguments
  direc (1,1) string
  time_req (1,1) datetime
  saveplot_fmt (1,:) string = string([])
  options.plotfun (1,1)
  options.xg (1,1) struct = struct()
  options.figures (1,:) matlab.ui.Figure
  options.visible (1,1) logical = true
  options.clim (1,1) struct = struct()
  % options.vars (1,:) string = string([])  % variables to plot (future)
end

import gemini3d.vis.bwr
import gemini3d.vis.plotfunctions.*

Ncmap = parula(256);
Tcmap = parula(256);
Phi_cmap = bwr();
Vcmap = bwr();
Jcmap = bwr();

lotsplots = true;   %@scivision may want to fix this...

%% READ IN THE SIMULATION INFORMATION (this is low cost so reread no matter what)
cfg = gemini3d.read_config(direc);

%% RELOAD GRID?
% loading grid can take a long time
if isempty(fieldnames(options.xg))
  disp('plotframe: Reloading grid...  Provide one as input if you do not want this to happen.')
  xg = gemini3d.readgrid(direc);
else
  xg = options.xg;
end

if any(contains(fieldnames(options), "figures"))
  h = options.figures;
else
  h = gemini3d.vis.plotinit(xg, options.visible);
end

if any(contains(fieldnames(options), "plotfun"))
  plotfun = gemini3d.vis.grid2plotfun(options.plotfun, xg);
else
  plotfun = gemini3d.vis.grid2plotfun("", xg);
end

%% get time index
i = interp1(cfg.times, 1:length(cfg.times), time_req, 'nearest');
if isnan(i)
  error('plotframe:value_error', 'requested time %s is outside simulation time span %s %s', datestr(time_req), datestr(cfg.times(1)), datestr(cfg.times(end)))
end
time = cfg.times(i);
%% LOAD THE FRAME NEAREST TO THE REQUESTED TIME
dat = gemini3d.vis.loadframe(direc, time);
disp(dat.filename + ' => ' + func2str(plotfun))

%% SET THE CAXIS LIMITS FOR THE PLOTS
%{
nelim =  [0 6e11];
v1lim = [-400 400];
Tilim = [100 3000];
Telim = [100 3000];
J1lim = [-25 25];
v2lim = [-10 10];
v3lim = [-10 10];
J2lim = [-10 10];
J3lim=[-10 10];
%}
lims = fieldnames(options.clim);
if ~any(contains(lims, "ne"))
  clim.ne =  [min(dat.ne(:)), max(dat.ne(:))];
end
if ~any(contains(lims, "v1"))
% v1mod=max(abs(v1(:)));
  v1mod = 80;
  clim.v1 = [-v1mod, v1mod];
end
if ~any(contains(lims, "Ti"))
  clim.Ti = [0, max(dat.Ti(:))];
end
if ~any(contains(lims, "Te"))
  clim.Te = [0, max(dat.Te(:))];
end
if ~any(contains(lims, "J1"))
  J1mod = max(abs(dat.J1(:)));
  clim.J1 = [-J1mod, J1mod];
end
if ~any(contains(lims, "v2"))
  v2mod = max(abs(dat.v2(:)));
  clim.v2 = [-v2mod, v2mod];
end
if ~any(contains(lims, "v3"))
  v3mod = max(abs(dat.v3(:)));
  clim.v3 = [-v3mod, v3mod];
end
if ~any(contains(lims, "J2"))
  J2mod = max(abs(dat.J2(:)));
  clim.J2 = [-J2mod, J2mod];
end
if ~any(contains(lims, "J3"))
  J3mod = max(abs(dat.J3(:)));
  clim.J3 = [-J3mod, J3mod];
end
if ~any(contains(lims, "Phitop"))
  clim.Phitop = [min(dat.Phitop(:)), max(dat.Phitop(:))];
end

%% MAKE THE PLOTS (WHERE APPROPRIATE)
%Electron number density, 'position', [.1, .1, .5, .5], 'units', 'normalized'
if lotsplots   % 3D simulation or a very long 2D simulation - do separate plots for each time frame

clf(h(10))
plotfun(time, xg, dat.ne, 'n_e (m^{-3})', clim.ne, [cfg.sourcemlat,cfg.sourcemlon], h(10), Ncmap);

if cfg.flagoutput ~= 3
  clf(h(1))
  plotfun(time, xg, dat.v1, 'v_1 (m/s)', clim.v1, [cfg.sourcemlat,cfg.sourcemlon], h(1), Vcmap);
  clf(h(2))
  plotfun(time, xg, dat.Ti,'T_i (K)', clim.Ti, [cfg.sourcemlat,cfg.sourcemlon], h(2), Tcmap);
  clf(h(3))
  plotfun(time, xg, dat.Te,'T_e (K)', clim.Te, [cfg.sourcemlat,cfg.sourcemlon], h(3), Tcmap);
  clf(h(4))
  plotfun(time, xg, dat.J1,'J_1 (A/m^2)', clim.J1, [cfg.sourcemlat,cfg.sourcemlon],h(4), Jcmap);
  clf(h(5))
  plotfun(time, xg, dat.v2,'v_2 (m/s)', clim.v2, [cfg.sourcemlat,cfg.sourcemlon],h(5), Vcmap);
  clf(h(6))
  plotfun(time, xg, dat.v3,'v_3 (m/s)', clim.v3, [cfg.sourcemlat,cfg.sourcemlon],h(6), Vcmap);
  clf(h(7))
  plotfun(time, xg, dat.J2,'J_2 (A/m^2)', clim.J2, [cfg.sourcemlat,cfg.sourcemlon],h(7), Jcmap);
  clf(h(8))
  plotfun(time, xg, dat.J3,'J_3 (A/m^2)', clim.J3, [cfg.sourcemlat,cfg.sourcemlon],h(8), Jcmap);
  clf(h(9))
%   try
  plotfun(time, xg, dat.Phitop,'topside potential \Phi_{top} (V)', clim.Phitop, [cfg.sourcemlat, cfg.sourcemlon], h(9), Phi_cmap)
%   catch e
%     % casting an error to warning requires this syntax for Matlab < R2020a
%     warning(e.identifier, '%s', e.message)
%   end
end

else    %short 2D simulation - put the entire time series in a single plot

figure(h(10)) %#ok<*UNRCH>
Rsp = 4;
Csp = 3;
ha = subplot(Rsp, Csp, it, 'parent',h(10));
nelim =  [9 11.3];
plotfun(time, xg,log10(ne), 'log_{10} n_e (m^{-3})', clim.ne,[cfg.sourcemlat,cfg.sourcemlon],ha);

if cfg.flagoutput ~= 3
  ha = subplot(Rsp, Csp,it,'parent',h(1));
  plotfun(time, xg, dat.v1(:,:,:),'v_1 (m/s)', clim.v1, [cfg.sourcemlat,cfg.sourcemlon],ha);

  ha = subplot(Rsp, Csp,it,'parent',h(2));
  plotfun(time, xg, dat.Ti(:,:,:),'T_i (K)', clim.Ti, [cfg.sourcemlat,cfg.sourcemlon],ha);

  ha = subplot(Rsp, Csp,it,'parent',h(3));
  plotfun(time, xg, dat.Te(:,:,:),'T_e (K)', clim.Te, [cfg.sourcemlat,cfg.sourcemlon],ha);

  ha = subplot(Rsp, Csp,it,'parent',h(4));
  plotfun(time, xg, dat.J1(:,:,:),'J_1 (A/m^2)', clim.J1, [cfg.sourcemlat,cfg.sourcemlon],ha);

  ha = subplot(Rsp, Csp,it,'parent',h(5));
  plotfun(time, xg, dat.v2(:,:,:),'v_2 (m/s)', clim.v2, [cfg.sourcemlat,cfg.sourcemlon],ha);

  ha = subplot(Rsp, Csp,it,'parent',h(6));
  plotfun(time, xg, dat.v3(:,:,:),'v_3 (m/s)', clim.v3, [cfg.sourcemlat,cfg.sourcemlon],ha);

  ha = subplot(Rsp, Csp,it,'parent',h(7));
  plotfun(time, xg, dat.J2(:,:,:),'J_2 (A/m^2)', clim.J2, [cfg.sourcemlat,cfg.sourcemlon],ha);

  ha = subplot(Rsp, Csp,it,'parent',h(8));
  plotfun(time, xg, dat.J3(:,:,:),'J_3 (A/m^2)', clim.J3, [cfg.sourcemlat,cfg.sourcemlon],ha);

  ha = subplot(Rsp, Csp,it,'parent',h(9));

%  plotfun(time, xg, dat.Phitop,'topside potential \Phi_{top} (V)', clim.Phitop, [p.sourcemlat, p.sourcemlon], h(9, Phi_cmap)
end

end


if lotsplots
  % for 3D or long 2D plots print and output file every time step
  gemini3d.vis.saveframe(cfg.flagoutput, direc, dat.filename, saveplot_fmt, h)
end

end % function plotframe
