{ pkgs ? import <nixpkgs> {} }:

pkgs.mkShell {
  name = "technet-installer-venv";

  buildInputs = with pkgs; [
    # System dependencies required for formatting and installation
    gptfdisk
    zfs
    parted
    util-linux
    wget

    # Python environment and venv automation
    python3
    python3Packages.textual
    python3Packages.venvShellHook
  ];

  # Path to the virtual environment directory
  venvDir = "./.venv";

  # Command to run after the venv is created and activated
  postShellHook = ''
    pip install -e .
    echo "TechNet Installer NixOS-based venv is ready for testing."
  '';
}