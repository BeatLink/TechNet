{ config, lib, pkgs, ... }:
{
  boot.initrd.availableKernelModules = [ "nvme" "xhci_pci" "uas" "usbhid" "sd_mod" ];
  boot.kernelModules = [ "kvm-amd" ];
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}