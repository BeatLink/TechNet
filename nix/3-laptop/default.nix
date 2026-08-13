# Module Imports
#

{
    technet.secrets.directory = "3-laptop";
    technet.waypipe.enable = true;
    technet.codecs.enable = true;

    imports = [
        ./1-system
        ./4-apps
    ];
}
