function particles_BCs(p, xg)
% create particle precipitation
arguments
  p (1,1) struct
  xg (1,1) struct
end

outdir = p.prec_dir;
gemini3d.fileio.makedir(outdir)

%% CREATE PRECIPITATION CHARACTERISTICS data
% number of grid cells.
% This will be interpolated to grid, so 100x100 is arbitrary
precip = struct('llon', 100, 'llat', 100);

if xg.lx(2) == 1    % cartesian
  precip.llon=1;
elseif xg.lx(3) == 1
  precip.llat=1;
end

%% TIME VARIABLE (seconds FROM SIMULATION BEGINNING)
% dtprec is set in config.nml
precip.times = p.times(1):seconds(p.dtprec):p.times(end);
Nt = length(precip.times);

%% CREATE PRECIPITATION INPUT DATA
% Qit: energy flux [mW m^-2]
% E0it: characteristic energy [eV]
% NOTE: since Fortran Gemini interpolates between time steps,
% having E0 default to zero is NOT appropriate, as the file before and/or
% after precipitation would interpolate from E0=0 to desired value, which
% is decidely non-physical.
% We default E0 to NaN so that it's obvious (by Gemini emitting an
% error) that an expected input has occurred.
precip.Qit = zeros(precip.llon, precip.llat, Nt);
precip.E0it = nan(precip.llon, precip.llat, Nt);

% did user specify on/off time? if not, assume always on.
% because of one-based Matlab indexing, i_on and i_off have a "+1"
if isfield(p, 'precip_startsec')
  i_on = round(p.precip_startsec / p.dtprec) + 1;
else
  i_on = 1;
end

if isfield(p, 'precip_endsec')
  i_off = round(min(p.tdur, p.precip_endsec) / p.dtprec) + 1;
else
  i_off = Nt;  % not +1
end

precip = gemini3d.setup.precip_grid(xg, p, precip);

mustBeFinite(p.E0precip)
mustBePositive(p.E0precip)
mustBeLessThan(p.E0precip, 100e6)
% ionization model vis relativistic particles 100MeV

% NOTE: in future, E0 could be made time-dependent in config.nml as 1D array
for i = i_on:i_off
   precip.Qit(:,:,i) = gemini3d.setup.precip_gaussian2d(precip, p.Qprecip, p.Qprecip_background);
   precip.E0it(:,:,i) = p.E0precip;
end

mustBeFinite(precip.Qit)
mustBeNonnegative(precip.Qit)

%% CONVERT THE ENERGY TO EV
%E0it = max(E0it,0.100);
%E0it = E0it*1e3;

gemini3d.write.precip(precip, outdir, p.file_format)

end % function
