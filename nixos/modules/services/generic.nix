{
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      PermitRootLogin = "no";
    };
    openFirewall = true;
  };

  services.timesyncd.enable = true;
}
