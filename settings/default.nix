{
  acme = import ./acme.nix;

  sshTrustedCA = [
    "ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBHZYMwtFA18EddsfU6NOLJoKdHQgbimAtXx11cFn28CD90G/jw6yxKPg+r1MhaJci3qzJtOzvETwD79R8sf9wtc= open-ssh-ca@cloudflareaccess.org"
  ];
}
