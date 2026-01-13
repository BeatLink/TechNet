{
    config,
    lib,
    pkgs,
    ...
}:

{
    # environment.systemPackages = with pkgs; [ dolphin ];
    home-manager.users.beatlink =
        { config, pkgs, ... }:
        {
            programs.plasma.configFile = {
                "baloofilerc" = {
                    "General" = {
                        "dbVersion" = 2;
                        "exclude filters" =
                            "*~,*.part,*.o,*.la,*.lo,*.loT,*.moc,moc_*.cpp,qrc_*.cpp,ui_*.h,cmake_install.cmake,CMakeCache.txt,CTestTestfile.cmake,libtool,config.status,confdefs.h,autom4te,conftest,confstat,Makefile.am,*.gcode,.ninja_deps,.ninja_log,build.ninja,*.csproj,*.m4,*.rej,*.gmo,*.pc,*.omf,*.aux,*.tmp,*.po,*.vm*,*.nvram,*.rcore,*.swp,*.swap,lzo,litmain.sh,*.orig,.histfile.*,.xsession-errors*,*.map,*.so,*.a,*.db,*.qrc,*.ini,*.init,*.tfstate*,*.class,*.pyc,*.pyo,*.elc,*.qmlc,*.jsc,*.fastq,*.fq,*.gb,*.fasta,*.fna,*.gbff,*.faa,po,CVS,.svn,.git,_darcs,.bzr,.hg,CMakeFiles,CMakeTmp,CMakeTmpQmake,.moc,.obj,.pch,.uic,.npm,.yarn,.yarn-cache,__pycache__,node_modules,node_packages,nbproject,.terraform,.venv,venv,core-dumps,lost+found";
                        "exclude filters version" = 9;
                        "folders[$e]" = "/Storage/Apps/,/Storage/Files/,/Storage/TechNet/,$HOME/";
                        "index hidden folders" = false;
                        "only basic indexing" = true;
                    };
                };
                "dolphinrc" = {
                    "General" = {
                        "FilterBar" = true;
                        "OpenExternallyCalledFolderInNewTab" = true;
                        "ShowFullPath" = true;
                        "ShowFullPathInTitlebar" = true;
                    };
                    "InformationPanel"."previewsAutoPlay" = true;
                    "KFileDialog Settings" = {
                        "Places Icons Auto-resize" = false;
                        "Places Icons Static Size" = 22;
                    };
                    "PreviewSettings"."Plugins" =
                        "appimagethumbnail,audiothumbnail,blenderthumbnail,comicbookthumbnail,cursorthumbnail,djvuthumbnail,ebookthumbnail,exrthumbnail,directorythumbnail,fontthumbnail,imagethumbnail,jpegthumbnail,kraorathumbnail,windowsexethumbnail,windowsimagethumbnail,mobithumbnail,opendocumentthumbnail,gsthumbnail,rawthumbnail,svgthumbnail,textthumbnail,ffmpegthumbs";
                };
            };
            home = {
                persistence."/Storage/Apps/System/Dolphin" = {
                    directories = [
                        ".local/share/dolphin"
                        ".local/share/baloo"
                    ];
                    files = [
                        ".config/dolphinrc"
                        ".local/share/recently-used.xbel"
                        ".local/share/user-places.xbel"
                        ".local/state/dolphinstaterc"
                    ];

                };
            };
        };
}
