{ config, lib, pkgs, ... }:
{
    programs.fuse.userAllowOther = true;
}