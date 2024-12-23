{ config, lib, pkgs, ... }:
{
  boot.initrd.availableKernelModules = [ "nvme" "xhci_pci" "uas" "usbhid" "sd_mod" ];
  boot.initrd.kernelModules = [ "nvidia" ];
  boot.kernelModules = [ "kvm-amd" "mt7921e" "ideapad_laptop" "nvidia"];
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
  hardware.enableRedistributableFirmware = true;
}
