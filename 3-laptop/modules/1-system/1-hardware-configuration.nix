{ config, lib, pkgs, ... }:
{
  boot = {
    initrd.availableKernelModules = [ "nvme" "xhci_pci" "uas" "usbhid" "sd_mod" ];
    initrd.kernelModules = ["nvidia"];
    kernelParams = ["amd_pstate=active"];
    kernelModules = [ "kvm-amd" "mt7921e" "ideapad_laptop"];
    extraModulePackages = [ config.boot.kernelPackages.nvidia_x11 ];
  };
  nixpkgs.hostPlatform = "x86_64-linux";
  hardware.cpu.amd.updateMicrocode = true;
  hardware.enableRedistributableFirmware = true;
}
