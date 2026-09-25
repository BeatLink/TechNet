# Backup Exclusions ##################################################################################################################################
#
# The one set of borg exclude patterns every backup in the fleet applies: borgmatic on each host, all of Vorta's profiles, and Vigil's backup runs.
# Borgmatic and Vigil read it from here, and a user unit in the Vorta module writes it into Vorta's settings database.
#

{ lib, ... }:
{
    options.backup-excludes = {
        markers = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            readOnly = true;
            description = "File names that exclude the directory holding them.";
            default = [ ".nobackup" ];
        };

        patterns = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            readOnly = true;
            description = "Borg exclude patterns, applied to every source directory of every backup.";
            default = [
                # Fleet Paths ########################################################################################################################
                "pf:/Storage/Files/Backups"
                "pf:/Storage/.pnpm-store"
                "pf:/Storage/Apps/Fun/Steam/home/beatlink/.local/share/Steam/steamapps/common"

                # Regenerable App Data ###############################################################################################################
                "fm:*/.lmstudio/models"
                "fm:*/.lmstudio/extensions"
                "fm:*/.lmstudio/disabled-mmproj"
                "fm:*/.stremio-server/stremio-cache"
                "fm:*/.claude/tmp"
                "fm:*/target"
                "fm:*/dist"
                "fm:*/build"
                "fm:*/cache2"
                "fm:*/startupCache"
                "fm:*/crashes"
                "fm:*/datareporting"
                "fm:*/saved-telemetry-pings"
                "fm:*/.config/VSCodium/CachedExtensionVSIXs"
                "fm:*/.config/*/Cache"
                "fm:*/.config/*/Code Cache"
                "fm:*/.config/*/CachedData"
                "fm:*/.config/*/GPUCache"
                "fm:*/.config/*/DawnCache"
                "fm:*/.config/*/ShaderCache"
                "fm:*/.config/*/Service Worker/CacheStorage"
                "fm:*/.config/trilium-*/Partitions"
                "fm:*/.claude/worktrees"
                "fm:*/CacheStorage"
                "fm:*/Code Cache"
                "fm:*/GPUCache"
                "fm:*/DawnCache"
                "fm:*/CachedData"
                "fm:*/htmlcache"
                "fm:*/cef/cache"
                "fm:*/default/*/cache"
                "fm:*/DawnWebGPUCache"
                "fm:*/DawnGraphiteCache"
                "fm:*/ScriptCache"
                "fm:*/shadercache"
                "fm:*/shaderhitcache"
                "fm:*/depotcache"
                "fm:*/appcache"
                "fm:*/component_crx_cache"
                "fm:*/Cache"
                "fm:*/Crashpad"
                "fm:*/Steam/steamapps/downloading"
                "fm:*/venv"
                "fm:*/.Trash-1000"
                "fm:*/.stversions"
                "fm:*/.thumbnails"

                # Vorta Preset: Spotify cache and config files #######################################################################################
                "fm:*/.cache/spotify"
                "fm:*/.config/spotify"
                "fm:*/.var/app/com.spotify.Client/cache"
                "fm:*/.var/app/com.spotify.Client/config/spotify"

                # Vorta Preset: Google Chrome cache and config files #################################################################################
                "fm:*/.cache/google-chrome"
                "fm:*/.cache/google-chrome-unstable"
                "fm:*/.config/google-chrome-unstable/*/Application Cache"
                "fm:*/.config/google-chrome-unstable/*/History Index *"
                "fm:*/.config/google-chrome-unstable/*/Local Storage"
                "fm:*/.config/google-chrome-unstable/*/Service Worker/CacheStorage"
                "fm:*/.config/google-chrome-unstable/*/Session Storage"
                "fm:*/.config/google-chrome-unstable/GrShaderCache"
                "fm:*/.config/google-chrome-unstable/GraphiteDawnCache"
                "fm:*/.config/google-chrome-unstable/ShaderCache"
                "fm:*/.config/google-chrome/*/Application Cache"
                "fm:*/.config/google-chrome/*/History Index *"
                "fm:*/.config/google-chrome/*/Local Storage"
                "fm:*/.config/google-chrome/*/Service Worker/CacheStorage"
                "fm:*/.config/google-chrome/*/Session Storage"
                "fm:*/.config/google-chrome/GrShaderCache"
                "fm:*/.config/google-chrome/GraphiteDawnCache"
                "fm:*/.config/google-chrome/ShaderCache"
                "fm:*/.var/app/com.google.Chrome/cache"
                "fm:*/.var/app/com.google.Chrome/config/google-chrome/*/Feature Engagement Tracker"
                "fm:*/.var/app/com.google.Chrome/config/google-chrome/*/Local Storage"
                "fm:*/.var/app/com.google.Chrome/config/google-chrome/*/Service Worker/CacheStorage"
                "fm:*/.var/app/com.google.Chrome/config/google-chrome/*/Session Storage"
                "fm:*/.var/app/com.google.Chrome/config/google-chrome/GrShaderCache"
                "fm:*/.var/app/com.google.Chrome/config/google-chrome/GraphiteDawnCache"
                "fm:*/.var/app/com.google.Chrome/config/google-chrome/Safe Browsing"
                "fm:*/.var/app/com.google.Chrome/config/google-chrome/ShaderCache"
                "fm:*/.var/app/com.google.ChromeDev/cache"
                "fm:*/.var/app/com.google.ChromeDev/config/google-chrome-unstable/*/Feature Engagement Tracker"
                "fm:*/.var/app/com.google.ChromeDev/config/google-chrome-unstable/*/Local Storage"
                "fm:*/.var/app/com.google.ChromeDev/config/google-chrome-unstable/*/Service Worker/CacheStorage"
                "fm:*/.var/app/com.google.ChromeDev/config/google-chrome-unstable/*/Session Storage"
                "fm:*/.var/app/com.google.ChromeDev/config/google-chrome-unstable/GrShaderCache"
                "fm:*/.var/app/com.google.ChromeDev/config/google-chrome-unstable/GraphiteDawnCache"
                "fm:*/.var/app/com.google.ChromeDev/config/google-chrome-unstable/Safe Browsing"
                "fm:*/.var/app/com.google.ChromeDev/config/google-chrome-unstable/ShaderCache"

                # Vorta Preset: Chromium cache and config files ######################################################################################
                "fm:*/.config/chromium/*/Application Cache"
                "fm:*/.config/chromium/*/History Index *"
                "fm:*/.config/chromium/*/Local Storage"
                "fm:*/.config/chromium/*/Service Worker/CacheStorage"
                "fm:*/.config/chromium/*/Session Storage"
                "fm:*/.config/chromium/GrShaderCache"
                "fm:*/.config/chromium/GraphiteDawnCache"
                "fm:*/.config/chromium/ShaderCache"
                "fm:*/.var/app/org.chromium.Chromium/cache"
                "fm:*/.var/app/org.chromium.Chromium/config/chromium/*/Application Cache"
                "fm:*/.var/app/org.chromium.Chromium/config/chromium/*/History Index *"
                "fm:*/.var/app/org.chromium.Chromium/config/chromium/*/Local Storage"
                "fm:*/.var/app/org.chromium.Chromium/config/chromium/*/Service Worker/CacheStorage"
                "fm:*/.var/app/org.chromium.Chromium/config/chromium/*/Session Storage"
                "fm:*/.var/app/org.chromium.Chromium/config/chromium/GrShaderCache"
                "fm:*/.var/app/org.chromium.Chromium/config/chromium/GraphiteDawnCache"
                "fm:*/.var/app/org.chromium.Chromium/config/chromium/ShaderCache"
                "fm:*/snap/chromium/*/.config/chromium/*/Service Worker/CacheStorage"
                "fm:*/snap/chromium/*/.local/share"
                "fm:*/snap/chromium/common/.cache"

                # Vorta Preset: Brave cache and config files #########################################################################################
                "fm:*/.cache/BraveSoftware/"
                "fm:*/.config/BraveSoftware/Brave-Browser/*/Feature Engagement Tracker"
                "fm:*/.config/BraveSoftware/Brave-Browser/*/Local Storage"
                "fm:*/.config/BraveSoftware/Brave-Browser/*/Service Worker/CacheStorage"
                "fm:*/.config/BraveSoftware/Brave-Browser/*/Session Storage"
                "fm:*/.config/BraveSoftware/Brave-Browser/GrShaderCache"
                "fm:*/.config/BraveSoftware/Brave-Browser/GraphiteDawnCache"
                "fm:*/.config/BraveSoftware/Brave-Browser/Safe Browsing"
                "fm:*/.config/BraveSoftware/Brave-Browser/ShaderCache"
                "fm:*/.var/app/com.brave.Browser/cache"
                "fm:*/.var/app/com.brave.Browser/config/BraveSoftware/Brave-Browser/*/Feature Engagement Tracker"
                "fm:*/.var/app/com.brave.Browser/config/BraveSoftware/Brave-Browser/*/Local Storage"
                "fm:*/.var/app/com.brave.Browser/config/BraveSoftware/Brave-Browser/*/Service Worker/CacheStorage"
                "fm:*/.var/app/com.brave.Browser/config/BraveSoftware/Brave-Browser/*/Session Storage"
                "fm:*/.var/app/com.brave.Browser/config/BraveSoftware/Brave-Browser/GrShaderCache"
                "fm:*/.var/app/com.brave.Browser/config/BraveSoftware/Brave-Browser/GraphiteDawnCache"
                "fm:*/.var/app/com.brave.Browser/config/BraveSoftware/Brave-Browser/Safe Browsing"
                "fm:*/.var/app/com.brave.Browser/config/BraveSoftware/Brave-Browser/ShaderCache"

                # Vorta Preset: Node Modules and package manager cache ###############################################################################
                "fm:*/node_modules"
                "fm:*/.npm"
                "fm:*/npm-global"

                # Vorta Preset: Mozilla Firefox cache and config files ###############################################################################
                "fm:*/.cache/mozilla/firefox"
                "fm:*/.mozilla/firefox/*/.parentlock"
                "fm:*/.mozilla/firefox/*/Cache"
                "fm:*/.mozilla/firefox/*/XPC.mfasl"
                "fm:*/.mozilla/firefox/*/XUL.mfasl"
                "fm:*/.mozilla/firefox/*/blocklist.xml"
                "fm:*/.mozilla/firefox/*/compreg.dat"
                "fm:*/.mozilla/firefox/*/extensions.cache"
                "fm:*/.mozilla/firefox/*/extensions.ini"
                "fm:*/.mozilla/firefox/*/extensions.rdf"
                "fm:*/.mozilla/firefox/*/extensions.sqlite"
                "fm:*/.mozilla/firefox/*/extensions.sqlite-journal"
                "fm:*/.mozilla/firefox/*/minidumps"
                "fm:*/.mozilla/firefox/*/pluginreg.dat"
                "fm:*/.mozilla/firefox/*/urlclassifier3.sqlite"
                "fm:*/.mozilla/firefox/*/xpti.dat"
                "fm:*/snap/firefox/common/.cache"
                "fm:*/snap/firefox/common/.mozilla/firefox/*/.parentlock"
                "fm:*/snap/firefox/common/.mozilla/firefox/*/XPC.mfasl"
                "fm:*/snap/firefox/common/.mozilla/firefox/*/XUL.mfasl"
                "fm:*/snap/firefox/common/.mozilla/firefox/*/blocklist.xml"
                "fm:*/snap/firefox/common/.mozilla/firefox/*/compreg.dat"
                "fm:*/snap/firefox/common/.mozilla/firefox/*/extensions.cache"
                "fm:*/snap/firefox/common/.mozilla/firefox/*/extensions.ini"
                "fm:*/snap/firefox/common/.mozilla/firefox/*/extensions.rdf"
                "fm:*/snap/firefox/common/.mozilla/firefox/*/extensions.sqlite"
                "fm:*/snap/firefox/common/.mozilla/firefox/*/extensions.sqlite-journal"
                "fm:*/snap/firefox/common/.mozilla/firefox/*/minidumps"
                "fm:*/snap/firefox/common/.mozilla/firefox/*/pluginreg.dat"
                "fm:*/snap/firefox/common/.mozilla/firefox/*/urlclassifier3.sqlite"
                "fm:*/snap/firefox/common/.mozilla/firefox/*/xpti.dat"
                "fm:*/.var/app/org.mozilla.firefox/.mozilla/firefox/*/.parentlock"
                "fm:*/.var/app/org.mozilla.firefox/.mozilla/firefox/*/XPC.mfasl"
                "fm:*/.var/app/org.mozilla.firefox/.mozilla/firefox/*/XUL.mfasl"
                "fm:*/.var/app/org.mozilla.firefox/.mozilla/firefox/*/blocklist.xml"
                "fm:*/.var/app/org.mozilla.firefox/.mozilla/firefox/*/compreg.dat"
                "fm:*/.var/app/org.mozilla.firefox/.mozilla/firefox/*/extensions.cache"
                "fm:*/.var/app/org.mozilla.firefox/.mozilla/firefox/*/extensions.ini"
                "fm:*/.var/app/org.mozilla.firefox/.mozilla/firefox/*/extensions.rdf"
                "fm:*/.var/app/org.mozilla.firefox/.mozilla/firefox/*/extensions.sqlite"
                "fm:*/.var/app/org.mozilla.firefox/.mozilla/firefox/*/extensions.sqlite-journal"
                "fm:*/.var/app/org.mozilla.firefox/.mozilla/firefox/*/minidumps"
                "fm:*/.var/app/org.mozilla.firefox/.mozilla/firefox/*/pluginreg.dat"
                "fm:*/.var/app/org.mozilla.firefox/.mozilla/firefox/*/urlclassifier3.sqlite"
                "fm:*/.var/app/org.mozilla.firefox/.mozilla/firefox/*/xpti.dat"
                "fm:*/.var/app/org.mozilla.firefox/cache"

                # Vorta Preset: Python cache and virtualenv ##########################################################################################
                "fm:*/__pycache__"
                "fm:*.pyc"
                "fm:*.pyo"
                "fm:*/.virtualenvs"
                "fm:*/venv/*"
                "fm:*/.venv/*"

                # Vorta Preset: Rust artefacts #######################################################################################################
                "fm:*/.cargo"
                "fm:*/.rustup"

                # Vorta Preset: Visual Studio Code cache and config files ############################################################################
                "fm:*/.config/Code"
                "fm:*/.vscode/extensions/*"

                # Vorta Preset: Android Studio Artefacts #############################################################################################
                "fm:*/.android"
                "fm:*/.gradle"
                "fm:*/Android/Sdk"
                "fm:*/.AndroidStudio"

                # Vorta Preset: Jetbrains IDEs cache, config, path and logs ##########################################################################
                "fm:*/.config/JetBrains"
                "fm:*/.cache/JetBrains"
                "fm:*/.local/share/JetBrains"

                # Vorta Preset: AWS artefacts ########################################################################################################
                "fm:*/.aws"

                # Vorta Preset: Flatpak Builder cache ################################################################################################
                "fm:*.flatpak-builder"

                # Vorta Preset: Docker artefacts #####################################################################################################
                "fm:*/.docker"

                # Vorta Preset: Log Files ############################################################################################################
                "fm:*.log"
                "fm:*/logs/*"

                # Vorta Preset: Java Development Artefacts ###########################################################################################
                "fm:*/.jdk/*"
                "fm:*/.m2/*"
                "fm:*/.gradle/*"

                # Vorta Preset: Temporary Files ######################################################################################################
                "fm:*/.tmp"
                "fm:*/temp"
                "fm:*.swp"
                "fm:*.bak"
                "fm:*.part"

                # Vorta Preset: All Cache Files ######################################################################################################
                "fm:*/.cache"
                "fm:*/Caches"
                "fm:*/.var/app/*/cache"
                "fm:*/.var/app/*/Cache"
                "fm:*/.var/app/*/Code Cache"
                "fm:*/.var/app/*/DawnCache"
                "fm:*/.var/app/*/GPUCache"
                "fm:*/.var/app/*/CacheStorage"
                "fm:*/.var/app/*/ScriptCache"
                "fm:*/.var/app/*/.ld.so"
                "fm:*/.var/app/*/tmp/*"

                # Vorta Preset: Recycle Bin/Trash ####################################################################################################
                "fm:*/.local/share/Trash/*"
                "fm:*/.Trash/*"
                "fm:*/.Trash-*/*"
            ];
        };
    };
}
