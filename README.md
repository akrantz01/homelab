# Homelab

The various configurations for my homelab.

### Client Configuration

To register a new minion to the SaltStack configuration, run the following command as root:

```sh
curl -fsSL https://raw.githubusercontent.com/akrantz01/homelab/main/onboard.sh | bash /dev/stdin <master address> <node id>
```
