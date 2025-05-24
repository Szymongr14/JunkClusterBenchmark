{pkgs, ...}: let
  # Replace with your real ip subnet.
  # For example, if your interface is 192.168.3.x/24, use dhcp-range=192.168.0.0,proxy
  myDhcpRange = "192.168.3.0,proxy";

  # tftpContent is a derivation that contains all files we want to serve via tftp
  # We build this derivation in tftp-content.nix file
  tftpContent = import ./tftp-content.nix {inherit pkgs;};
in {
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

  # Symlink tftp-root for convenience (Optional)
  # Inspect the directory with ls /srv/tftp-root instead of finding /nix/store path
  systemd.tmpfiles.rules = [
    # L+ means: create a symlink.
    # If it's a symlink pointing elsewhere, update it.
    # Symlink target is the store path of tftpContent
    "L+ /srv/tftp-root - - - - ${tftpContent}"
  ];

  # Configure networking
  networking = {
    hostName = "pxe-vm";
    useDHCP = true;
    firewall.enable = false;
  };

  environment.etc."resolv.conf".text = ''
    # Static /etc/resolv.conf defined in NixOS configuration
    nameserver 1.1.1.1
    nameserver 1.0.0.1
    options edns0
  '';

  environment.systemPackages = with pkgs; [
    tcpdump
  ];

  # Set password
  users.users.root.initialPassword = "nixos";

  system.stateVersion = "25.11";
}
