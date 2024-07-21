{host, ...}: {
  sops = {
    defaultSopsFile = ./nix/${host.hostname}/default.yaml;

    age.sshKeyPaths = ["/etc/ssh/ssh_host_ed25519_key"];
  };
}
