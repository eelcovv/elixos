{
  systemd.services.generate-ssh-pubkey = {
    description = "Generate id_ed25519.pub from id_ed25519";
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      User = "eelco";
      ExecStart = ''
        if [ -f /home/eelco/.ssh/id_ed25519 ]; then
          ${pkgs.openssh}/bin/ssh-keygen -y -f /home/eelco/.ssh/id_ed25519 > /home/eelco/.ssh/id_ed25519.pub
        fi
      '';
    };
  };
}
