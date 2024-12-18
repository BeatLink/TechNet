{ config, lib, pkgs, ... }:
{
    programs.plasma.configFile.kwinrc =  {
        Effect-overview.BorderActivate = 5;
        Effect-windowview.BorderActivateAll = 3;
        ElectricBorders.TopRight = "ShowDesktop";

    };
}


/*[Desktops]
Id_1=85fc98df-c7a1-479d-a8d7-8bcf82b11a90
Id_2=dcecc56f-66ef-463a-9438-3640ac701388
Number=2
Rows=1


[]


[]


[Tiling]
padding=4

[Tiling][06f67c8d-4c4f-5f57-bc07-57b608903218]
tiles={"layoutDirection":"horizontal","tiles":[{"width":0.25},{"width":0.5},{"width":0.25}]}

[Tiling][491ad143-cec5-5bbf-8dd5-ed3621863621]
tiles={"layoutDirection":"horizontal","tiles":[{"width":0.25},{"width":0.5},{"width":0.25}]}

[Windows]
ElectricBorderCooldown=550

[Xwayland]
Scale=1.25
 */