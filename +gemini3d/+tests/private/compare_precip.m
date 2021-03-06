function compare_precip(tc, times, prec_dir, ref_prec_dir, opts)
arguments
  tc (1,1) matlab.unittest.TestCase
  times (1,:) datetime
  prec_dir (1,1) string
  ref_prec_dir (1,1) string
  opts.rel (1,1) {mustBePositive}
  opts.abs (1,1) {mustBePositive}
end

% often we reuse precipitation inputs without copying over files
for i = 1:size(times)
  ref = gemini3d.read.precip(ref_prec_dir, times(i));
  new = gemini3d.read.precip(prec_dir, times(i));

  tc.assertNotEmpty(ref, "reference " + ref_prec_dir + " does not contain precipitation data")
  tc.assertNotEmpty(new, "data " + prec_dir + " does not contain precipitation data")

  for k = ["E0", "Q"]
    b = ref.(k);
    a = new.(k);

    reltol = cast(opts.rel, 'like', a);
    abstol = cast(opts.abs, 'like', a);

    tc.verifySize(a, size(b), "ref shape != data shape: " + k)

    tc.verifyEqual(a, b, 'RelTol', reltol, 'AbsTol', abstol, "mismatch: " + k)
  end
end % for i

disp("OK: precipitation input " + prec_dir)

end % function
