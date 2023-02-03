# The Evil Lair

Deploys the [SaltStack](https://saltproject.io) master for managing configuration on various minions on [AWS](https://aws.amazon.com) using [Terraform](https://www.terraform.io).
The SaltStack master is configured to automatically pull configuration from this repository triggered by a GitHub webhook.

It is called the evil lair because the server houses all the configuration for the minions.
The name is also way more fun than just calling it "master" or something.
