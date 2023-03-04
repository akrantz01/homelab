sudoers:
  manage_main_config: true

  users:
    root:
      - "ALL=(ALL:ALL) ALL"
    alex:
      - "ALL=(ALL:ALL) NOPASSWD: ALL"
  
  purge_includedir: true
  includedir: /etc/sudoers.d
