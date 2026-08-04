# Shader cache
#
# Mesa compiles GLSL to machine code the first time a program needs it and
# caches the result under ~/.cache/mesa_shader_cache. On these hosts / is rolled
# back to a blank snapshot at every boot, and that directory is not persisted --
# so the cache is empty on every boot and every shader is compiled again.
#
# Measured on Thor: 105 entries, every one written during the current boot.
#
# Persisting it is the cheapest possible trade of storage for CPU. 1.2MB, and
# what it buys back is shader compilation at the moment the compositor and the
# first application start -- exactly when a 1.15GHz A53 has the least to spare
# and the stutter is most visible.
#
# Shared rather than phone-only because the gap is impermanence, not hardware:
# Odin rolls back the same way. It matters less there, having the cores to
# absorb it, but the cache is equally discarded and equally cheap to keep.
#
# Safe to lose: Mesa keys entries by driver build and regenerates anything stale
# or missing, so a wiped or out-of-date cache costs the compile it would have
# cost anyway rather than breaking rendering.
#
{
    home-manager.users.beatlink = {
        home.persistence."/Storage/Apps/System/ShaderCache" = {
            directories = [ ".cache/mesa_shader_cache" ];
        };
    };
}
