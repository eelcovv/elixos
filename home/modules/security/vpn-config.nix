{
  config,
  lib,
  pkgs,
  ...
}: {
  # Write ~/.config/vpn-endpoints as key=value lines (no comments)
  home.file.".config/surfshark-endpoints" = {
    text = ''
      bk=th-bkk.prod.surfshark.com:51820
      sg=sg-sng.prod.surfshark.com:51820
      ff=sg-sng.prod.surfshark.com:51820
      nl=143.244.42.89:51820
    '';
    # Note: no 'mode' option supported here; HM manages perms.
  };
}
