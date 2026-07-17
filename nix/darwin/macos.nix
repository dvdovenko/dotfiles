{ ... }:

{
  # Deliberately small and easy to prune — add to this as you find defaults
  # you actually want, rather than dumping every known `system.defaults` knob.
  system.defaults = {
    NSGlobalDomain.InitialKeyRepeat = 15;
    NSGlobalDomain.KeyRepeat = 2;
    dock.autohide = true;
    finder.AppleShowAllExtensions = true;
  };

  security.pam.services.sudo_local.touchIdAuth = true;
}
