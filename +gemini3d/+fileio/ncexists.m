function exists = ncexists(filename, varnames)
% check if variable(s) exists in NetCDF4 file
%
% filename: NetCDF4 filename
% varname: name of variable inside file
%
% exists: boolean (scalar or vector)

arguments
  filename (1,1) string
  varnames (1,:) string
end

% NOT contains because we want exact string match
exists = ismember(varnames, gemini3d.fileio.ncvariables(filename));

end % function
