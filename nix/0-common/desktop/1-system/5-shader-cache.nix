# Shader cache
#
# Persists Mesa's compiled shader cache across the impermanence rollback, so
# shaders are not recompiled from scratch at every boot.
#
{
    home-manager.users.beatlink.home.persistence."/Storage/Apps/System/ShaderCache".directories = [
        ".cache/mesa_shader_cache"
    ];
}
