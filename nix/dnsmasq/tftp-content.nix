{pkgs}: let
  netbootXyzLkrn = pkgs.fetchurl {
    url = "https://boot.netboot.xyz/ipxe/netboot.xyz.lkrn";
    sha256 = "0az4v6jipcc18r3ygx89nnxz9sa1712n1ahhc8qmja2kn37qissw";
  };

  pxeDefaultConfig = pkgs.writeText "default" ''
    DEFAULT netboot
    PROMPT 0
    TIMEOUT 30 # 3 seconds timeout

    LABEL netboot
       MENU LABEL Boot netboot.xyz
       KERNEL netboot.xyz.lkrn
  '';
in
  pkgs.stdenv.mkDerivation {
    name = "pxe-tftp-content";
    srcs = [
      netbootXyzLkrn
      pxeDefaultConfig
      "${pkgs.syslinux}/share/syslinux/pxelinux.0"
      "${pkgs.syslinux}/share/syslinux/ldlinux.c32"
    ];

    # No unpacking needed, these are all just files or paths to files.
    dontUnpack = true;

    installPhase = ''
      runHook preInstall

      mkdir -p $out/pxelinux.cfg

      cp ${netbootXyzLkrn} $out/netboot.xyz.lkrn

      cp ${pxeDefaultConfig} $out/pxelinux.cfg/default

      cp ${pkgs.syslinux}/share/syslinux/pxelinux.0 $out/pxelinux.0

      cp ${pkgs.syslinux}/share/syslinux/ldlinux.c32 $out/ldlinux.c32

      chmod -R a+r $out
      find $out -type d -exec chmod a+x {} \;

      runHook postInstall
    '';

    dontBuild = true;
    dontConfigure = true;
    dontPatch = true;
    dontFixup = true;
  }
