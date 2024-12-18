{ config, lib, pkgs, ... }:
{
    programs.plasma.panels = [
        {
            location = "top";
            height = 32;
            lengthMode = "fill";
            hiding = "none";
            floating = true;
            /*widgets = [

            ]*/
        }
    ];
}