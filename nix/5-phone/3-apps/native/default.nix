# Native applications
#
# Applications installed into the phone's own closure and run against its hardware directly.
#
{
    imports = [
        ./camera.nix
        ./nemo.nix
        ./phone.nix
        ./sms.nix
        ./toolkit-comparison.nix
        ./xed.nix
    ];
}
