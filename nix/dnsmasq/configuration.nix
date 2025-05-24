{pkgs, ...}: let
  # Replace with your real ip subnet.
  # For example, if your interface is 192.168.3.x/24, use dhcp-range=192.168.0.0,proxy
  myDhcpRange = "192.168.3.0,proxy";

  # tftpContent is a derivation that contains all files we want to serve via tftp
  # We build this derivation in tftp-content.nix file
  tftpContent = import ./tftp-content.nix {inherit pkgs;};
in {
  networking.hostName = "pxe-vm";
  networking.useDHCP = true;

  services.dnsmasq = {
    enable = true;
    settings = {
      # Disable built-in DNS
      port = 0;

      # Listen only on PXE server interface
      interface = "enp1s0";
      bind-interfaces = true;

      # Enable PXE proxy-dhcp mode
      dhcp-range = myDhcpRange;

      # PXE bootloarder
      dhcp-boot = "pxelinux.0";

      # Enable tftp
      enable-tftp = true;
      tftp-root = "${tftpContent}";

      # Menu label
      pxe-service = "x86PC, \"NixOS PXE Server (netboot.xyz - BIOS)\", pxelinux.0";

      # Logging
      log-dhcp = true;
      log-queries = true;
    };
  };

  networking.firewall.enable = false;

  # PXELINUX and required files
  environment.systemPackages = with pkgs; [
    syslinux # for pxelinux.0, ldlinux.c32, etc.
  ];

  systemd.tmpfiles.rules = [
    # L+ means: create a symlink.
    # If it's a symlink pointing elsewhere, update it.
    # Symlink target is the store path of tftpContent
    "L+ /srv/tftp-root - - - - ${tftpContent}"
  ];


  users.users.root.initialPassword = "nixos";

  system.stateVersion = "25.11";
}
