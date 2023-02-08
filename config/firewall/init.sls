/etc/nftables.conf:
  file.managed:
    - source: salt://firewall/nftables.conf
    - user: root
    - group: root
    - mode: 0755
