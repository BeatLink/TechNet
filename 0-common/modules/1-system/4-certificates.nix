
{ config, lib, pkgs, modulesPath, ... }: 
{
    # Add TechNet Certificate for Websites
    security.pki.certificates = [ 
        ''
            -----BEGIN CERTIFICATE-----
            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
            wg==
            -----END CERTIFICATE-----
        ''
    ];
}