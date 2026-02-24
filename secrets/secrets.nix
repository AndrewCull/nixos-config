let
  # ── Host keys (age format) ─────────────────────────
  # Obtain with: ssh-to-age < /etc/ssh/ssh_host_ed25519_key.pub
  p14s = "age1XXXX";   # TODO: replace after first rebuild
  xps13 = "age1ng3dwcs92k0fk7g868zrlu9s8e5edh7c4u9csp7wnhydd6tqgfzs3d6ffe";  # TODO: replace after first rebuild

  allHosts = [ xps13 ];  # TODO: add p14s after getting its host key
in {
  "secrets/id_ed25519.age".publicKeys = allHosts;
}
