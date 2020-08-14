function hash = md5sum(file)
% compute MD5 hash of file
import gemini3d.fileio.*

narginchk(1,1)

file = expanduser(file);

assert(is_file(file), '%s not found', file)

hash = [];

if verLessThan('matlab', '9.7')
  return
end
p = pyenv();
if isempty(char(p.Version)) % Python not configured
  return
end
h = py.hashlib.md5();
h.update(py.pathlib.Path(file).read_bytes())
hash = char(h.hexdigest());

%% sanity check
assert(length(hash)==32, 'md5 hash is 32 characters')

end % function