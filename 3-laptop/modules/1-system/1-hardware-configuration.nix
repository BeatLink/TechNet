{ config, lib, pkgs, ... }:
{
  boot.initrd.availableKernelModules = [ "nvme" "xhci_pci" "uas" "usbhid" "sd_mod" ];
  boot.initrd.kernelModules = ["nvidia"];
  boot.kernelParams = ["amd_pstate=active"];
  boot.kernelModules = [ "kvm-amd" "mt7921e" "ideapad_laptop"];
  nixpkgs.hostPlatform = "x86_64-linux";
  hardware.cpu.amd.updateMicrocode = true;
  hardware.enableRedistributableFirmware = true;
}
