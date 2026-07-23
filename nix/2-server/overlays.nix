# Overlay to work around an upstream test regression in python-ulid: its
# test_same_millisecond_overflow test fails under the currently-pinned
# nixpkgs (freezegun/ulid version mismatch causes the expected ValueError to
# not raise). This blocks Vigil's build (pulled in transitively via
# fastapi -> pydantic-extra-types -> python-ulid). Skipping the package's
# own test suite doesn't change its runtime behavior.
{
    nixpkgs.overlays = [
        (final: prev: {
            python312 = prev.python312.override {
                packageOverrides = pyFinal: pyPrev: {
                    python-ulid = pyPrev.python-ulid.overridePythonAttrs (old: {
                        doCheck = false;
                    });
                };
            };
        })
    ];
}
