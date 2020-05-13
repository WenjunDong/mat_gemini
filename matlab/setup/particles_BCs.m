function particles_BCs(p, xg)
% create particle precipitation
narginchk(2,2)
validateattributes(p, {'struct'}, {'scalar'})
validateattributes(xg, {'struct'}, {'scalar'})
%% CREATE PRECIPITATION CHARACTERISTICS data
% number of grid cells.
% This will be interpolated to grid, so 100x100 is arbitrary
llon=100;
llat=100;

if xg.lx(2) == 1    % cartesian
  llon=1;
elseif xg.lx(3) == 1
  llat=1;
end

%% TIME VARIABLE (SECONDS FROM SIMULATION BEGINNING)
% dtprec is set in config.nml
time = 0:p.dtprec:p.tdur;
Nt = numel(time);

%% time
UTsec = p.UTsec0 + time;     % seconds from beginning of hour
UThrs = UTsec/3600;
expdate=cat(2,repmat(p.ymd(:)',[Nt,1]),UThrs(:),zeros(Nt,1),zeros(Nt,1));

%% CREATE PRECIPITATION INPUT DATA
% Qit: energy flux [mW m^-2]
% E0it: characteristic energy [eV]
Qit = zeros(llon, llat, Nt);
E0it = zeros(llon,llat, Nt);

% did user specify on/off time? if not, assume always on.
if isfield(p, 'precip_startsec')
  [~, i_on] = min(abs(time - p.precip_startsec));
else
  i_on = 1;
end

if isfield(p, 'precip_endsec')
  [~, i_off] = min(abs(time - p.precip_endsec));
else
  i_off = Nt;
end

pg = precip_grid(xg, p, llat, llon);

for i = i_on:i_off
   Qit(:,:,i) = precip_gaussian2d(pg, p.Qprecip, p.Qprecip_background);
  E0it(:,:,i) = p.E0precip;
end

if any(~isfinite(Qit)), error('particle_BCs:value_error', 'precipitation flux not finite'), end
if any(~isfinite(E0it)), error('particle_BCs:value_error', 'E0 not finite'), end

%% CONVERT THE ENERGY TO EV
%E0it = max(E0it,0.100);
%E0it = E0it*1e3;

%% SAVE to files
% LEAVE THE SPATIAL AND TEMPORAL INTERPOLATION TO THE
% FORTRAN CODE IN CASE DIFFERENT GRIDS NEED TO BE TRIED.
% THE EFIELD DATA DO NOT NEED TO BE SMOOTHED.

outdir = absolute_path(p.prec_dir);
makedir(outdir)

disp(['write to ',outdir])
switch p.file_format
  case {'h5','hdf5'}, write_hdf5(outdir, llon, llat, pg.mlon, pg.mlat, expdate, Nt, Qit, E0it)
  case {'dat','raw'}, write_raw(outdir, llon, llat, pg.mlon, pg.mlat, expdate, Nt, Qit, E0it, p.realbits)
  case {'nc', 'nc4'}, write_nc4(outdir, llon, llat, pg.mlon, pg.mlat, expdate, Nt, Qit, E0it)
  otherwise, error('particles_BCs:value_error', 'unknown file format %s', p.file_format)
end

end % function


function write_hdf5(outdir, llon, llat, mlon, mlat, expdate, Nt, Qit, E0it)
narginchk(9,9)
fn = fullfile(outdir, 'simsize.h5');
h5save(fn, '/llon', int32(llon))
h5save(fn, '/llat', int32(llat))

freal = 'float32';

fn = fullfile(outdir, 'simgrid.h5');
h5save(fn, '/mlon', mlon, [], freal)
h5save(fn, '/mlat', mlat, [], freal)

for i = 1:Nt
  UTsec = expdate(i,4)*3600 + expdate(i,5)*60 + expdate(i,6);
  ymd = expdate(i, 1:3);

  fn = fullfile(outdir, [datelab(ymd,UTsec), '.h5']);

  h5save(fn, '/Qp', Qit(:,:,i), [llon, llat], freal)
  h5save(fn, '/E0p', E0it(:,:,i),[llon, llat], freal)
end

end % function


function write_nc4(outdir, llon, llat, mlon, mlat, expdate, Nt, Qit, E0it)
narginchk(9,9)

fn = fullfile(outdir, 'simsize.nc');
ncsave(fn, 'llon', int32(llon))
ncsave(fn, 'llat', int32(llat))

freal = 'float32';

fn = fullfile(outdir, 'simgrid.nc');
ncsave(fn, 'mlon', mlon, {'lon', length(mlon)}, freal)
ncsave(fn, 'mlat', mlat, {'lat', length(mlat)}, freal)

for i = 1:Nt
  UTsec = expdate(i,4)*3600 + expdate(i,5)*60 + expdate(i,6);
  ymd = expdate(i, 1:3);

  fn = fullfile(outdir, [datelab(ymd,UTsec), '.nc']);

  ncsave(fn, 'Qp', Qit(:,:,i), {'lon', length(mlon), 'lat', length(mlat)}, freal)
  ncsave(fn, 'E0p', E0it(:,:,i), {'lon', length(mlon), 'lat', length(mlat)}, freal)
end

end % function


function write_raw(outdir, llon, llat, mlon, mlat, expdate, Nt, Qit, E0it, realbits)
narginchk(10,10)

filename= fullfile(outdir, 'simsize.dat');
fid=fopen(filename, 'w');
fwrite(fid,llon,'integer*4');
fwrite(fid,llat,'integer*4');
fclose(fid);

freal = ['float', int2str(realbits)];

filename = fullfile(outdir, 'simgrid.dat');

fid=fopen(filename,'w');
fwrite(fid,mlon, freal);
fwrite(fid,mlat, freal);
fclose(fid);

for i = 1:Nt
  UTsec = expdate(i,4)*3600 + expdate(i,5)*60 + expdate(i,6);
  ymd = expdate(i, 1:3);

  filename = fullfile(outdir, [datelab(ymd,UTsec), '.dat']);

  fid = fopen(filename,'w');
  fwrite(fid,Qit(:,:,i), freal);
  fwrite(fid,E0it(:,:,i), freal);
  fclose(fid);
end

end % function
