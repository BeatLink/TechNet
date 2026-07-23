# Vigil (via fastapi/nicegui) pulls in a chain of python312Packages whose
# upstream test suites are broken/flaky on the currently-pinned nixpkgs
# revision:
#   - python-ulid: test_same_millisecond_overflow fails (freezegun/ulid
#     version mismatch, expected ValueError doesn't raise)
#   - aiohttp: test_static_file_if_range_future_with_range times out making
#     a real network connection during the sandboxed build
# Skipping each package's own test suite doesn't change its runtime
# behavior. Expect to add more entries here if other transitive deps hit
# the same class of issue before nixpkgs is bumped past it.
{
    nixpkgs.overlays = [
        (final: prev: {
            python312 = prev.python312.override {
                packageOverrides = pyFinal: pyPrev: {
                    python-ulid = pyPrev.python-ulid.overridePythonAttrs (old: {
                        doCheck = false;
                    });
                    aiohttp = pyPrev.aiohttp.overridePythonAttrs (old: {
                        doCheck = false;
                    });
                };
            };
        })
    ];
}
