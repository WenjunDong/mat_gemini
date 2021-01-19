function atmos = msis(p, xg, time)
%% calls MSIS Fortran executable from Matlab.
% compiles if not present
%
% [f107a, f107, ap] = activ;
%     COLUMNS OF DATA:
%       1 - ALT
%       2 - HE NUMBER DENSITY(M-3)
%       3 - O NUMBER DENSITY(M-3)
%       4 - N2 NUMBER DENSITY(M-3)
%       5 - O2 NUMBER DENSITY(M-3)
%       6 - AR NUMBER DENSITY(M-3)
%       7 - TOTAL MASS DENSITY(KG/M3)
%       8 - H NUMBER DENSITY(M-3)
%       9 - N NUMBER DENSITY(M-3)
%       10 - Anomalous oxygen NUMBER DENSITY(M-3)
%       11 - TEMPERATURE AT ALT
arguments
  p (1,1) struct
  xg (1,1) struct
  time (1,1) datetime = p.times(1)
end

cwd = fileparts(mfilename('fullpath'));
run(fullfile(cwd, '../../setup.m'))

%% path to msis executable
src_dir = getenv("GEMINI_ROOT");
build_dir = fullfile(src_dir, "build");
exe = gemini3d.sys.exe_name(fullfile(build_dir, "msis_setup"));

%% build exe if not present
if ~isfile(exe)
  gemini3d.sys.cmake(src_dir, build_dir, "msis_setup")
end

assert (isfile(exe), 'MSIS setup executable not found: %s', exe)

%% SPECIFY SIZES ETC.
alt=xg.alt/1e3;
%% CONVERT DATES/TIMES/INDICES INTO MSIS-FRIENDLY FORMAT
if isfield(p, 'activ')
  f107a = p.activ(1);
  f107 = p.activ(2);
  ap = p.activ(3);
else
  f107a = p.f107a;
  f107 = p.f107;
  ap = p.Ap;
end

doy = day(time, 'dayofyear');
UTsec0 = seconds(time - datetime(time.Year, time.Month, time.Day));
% KLUDGE THE BELOW-ZERO ALTITUDES SO THAT THEY DON'T GIVE INF
alt(alt <= 0) = 1;
%% MSIS file API
% we use binary files because they are MUCH faster than stdin/stdout pipes

if isfield(p, "msis_infile")
  msis_infile = p.msis_infile;
else
  msis_infile = fullfile(fileparts(p.indat_size), "msis_setup_in.h5");
end
if isfield(p, "msis_outfile")
  msis_outfile = p.msis_outfile;
else
  msis_outfile = fullfile(fileparts(p.indat_size), "msis_setup_out.h5");
end

if isfile(msis_infile)
  delete(msis_infile)
end
if isfile(msis_outfile)
  delete(msis_outfile)
end

hdf5nc.h5save(msis_infile, "/doy", doy)
hdf5nc.h5save(msis_infile, "/UTsec", UTsec0)
hdf5nc.h5save(msis_infile, "/f107a", f107a)
hdf5nc.h5save(msis_infile, "/f107", f107)
hdf5nc.h5save(msis_infile, "/Ap", repmat(ap, [1, 7]))
% float32 to save disk IO time/space
% ensure the disk array has 3 dimensions--Matlab collapses to 2D and that's not
% suitable for Fortran
hdf5nc.h5save(msis_infile, "/glat", xg.glat, 'size', xg.lx, 'type', 'float32');
hdf5nc.h5save(msis_infile, "/glon", xg.glon, 'size', xg.lx, 'type', 'float32');
hdf5nc.h5save(msis_infile, "/alt", alt, 'size', xg.lx, 'type', 'float32');

%% CALL MSIS
cmd = exe + " " + msis_infile + " " + msis_outfile;
if isfield(p, "msis_version") && ~isempty(p.msis_version)
  cmd = cmd + " " + int2str(p.msis_version);

  if p.msis_version == 20
    msis20_file = fullfile(build_dir, 'msis20.parm');
    if ~isfile(msis20_file)
      error("msis:param:fileNotFound", "%s not found", msis20_file)
    end
  end
end
% disp(cmd)

% limitation of Matlab system() vis pwd for msis20.parm
old_pwd = pwd;
cd(build_dir)
[status, msg] = system(cmd);   %output written to file
cd(old_pwd)
assert(status==0, 'problem running MSIS %s', msg)

%% load MSIS output
atmos.nO = h5read(msis_outfile, "/nO");
atmos.nN2 = h5read(msis_outfile, "/nN2");
atmos.nO2 = h5read(msis_outfile, "/nO2");
atmos.Tn = h5read(msis_outfile, "/Tn");
atmos.nN = h5read(msis_outfile, "/nN");
atmos.nNO = 0.4 * exp(-3700./ atmos.Tn) .* atmos.nO2 + 5e-7* atmos.nO;       %Mitra, 1968
atmos.nH = h5read(msis_outfile, "/nH");

end % function
