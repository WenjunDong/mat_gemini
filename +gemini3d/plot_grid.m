function h = plot_grid(xg, extra)
%% plot 3D grid
%
% xg: file containing grid or struct of grid

arguments
  xg
  extra (1,:) string = string.empty
end

if ~isstruct(xg)
  xg = gemini3d.readgrid(xg);
end

assert(~isempty(xg), "not contain a readable simulation grid")

h = [];
%% x1, x2, x3
if isempty(extra) || any(extra == "basic")
  h(end+1) = basic(xg);
end
%% detailed altitude plot
if any(extra == "alt")
  h(end+1) = gemini3d.vis.plot_altitude_grid(xg);
end
%% ECEF surface
if any(extra == "ecef")
  fig3 = figure;
  ax = axes('parent', fig3);
  scatter3(xg.x(:), xg.y(:), xg.z(:), 'parent', ax)
  stitle(fig3, xg, "ECEF")
  xlabel(ax, 'x [m]')
  ylabel(ax, 'y [m]')
  zlabel(ax, 'z [m]')
  view(ax, 0, 0)
  h(end+1) = fig3;
end
%%
if nargout == 0, clear('h'), end
end % function


function fig1 = basic(xg)
fig1 = figure();
t = tiledlayout(fig1, 1, 3);
h = fig1;
%% x1
lx1 = length(xg.x1);
ax = nexttile(t);
plot(ax, 1:lx1, xg.x1/1e3, 'marker', '.')
ylabel(ax, 'x1 [km]')
xlabel(ax, 'index (dimensionless)')
title(ax, {"x1 (upward)", "lx1 = " + int2str(lx1)})

%% x2
lx2 = length(xg.x2);
ax = nexttile(t);
plot(ax, xg.x2/1e3, 1:lx2, 'marker', '.')
xlabel(ax, 'x2 [km]')
ylabel(ax, 'index (dimensionless)')
title(ax, {"x2 (eastward)", "lx2 = " + int2str(lx2)})

%% x3
lx3 = length(xg.x3);
ax = nexttile(t);
plot(ax, 1:lx3, xg.x3/1e3, 'marker', '.')
ylabel(ax, 'x3 [km]')
xlabel(ax, 'index (dimensionless)')
title(ax, {"x3 (northward)", "lx3 = " + int2str(lx3)})

stitle(fig1, xg)
end


function stitle(fig, xg, ttxt)
arguments
  fig (1,1) matlab.ui.Figure
  xg (1,1) struct
  ttxt (1,1) string = ""
end
%% suptitle
if isfield(xg, 'time')
  ttxt = ttxt + datestr(xg.time) + " ";
end

if isfield(xg, 'filename')
  ttxt = ttxt + xg.filename;
end

sgtitle(fig, ttxt, 'interpreter', 'none')
end