{
  pkgs,
  accounts ? [],
}: {
  programs.thunderbird = {
    enable = true;
    package = pkgs.thunderbird;
    profiles.default.isDefault = true;
  };

  accounts.email.accounts = builtins.listToAttrs (
    map (addr: {
      name = addr;
      value = {thunderbird.enable = true;};
    })
    accounts
  );
}
