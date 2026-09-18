# Shader Cache #######################################################################################################################################
#
# Persists the Mesa and NVIDIA shader caches across the impermanence rollback so shaders are not recompiled at every boot.
#

{
    home-manager.users.beatlink.home.persistence."/Storage/Apps/System/ShaderCache".directories = [
        ".cache/mesa_shader_cache"
        ".cache/nvidia"
        ".nv/ComputeCache"
    ];
}
