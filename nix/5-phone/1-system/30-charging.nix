{ inputs, ... }:
{
    imports = [ inputs.pinephone-charge.nixosModules.default ];

    services.chargectl = {
        enable = true;
        profile = "maintain";
        group = "beatlink";
        band = {
            low = 75;
            high = 80;
        };
    };

    environment.persistence."/persistent".directories = [ "/var/lib/chargectl" ];
}
