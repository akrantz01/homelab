---
name: General
description: General development environment for multiple languages
tags: [local, docker]
icon: /icon/docker.png
---

# General

Contains a general development environment for multiple languages with support for multiple IDEs.

The following languages and tools are pre-installed:
- Python 3
  - Poetry
  - pipx
- Node.js
  - yarn
- Go
- Rust

## code-server

`code-server` is installed via the `startup_script` argument in the `coder_agent`
resource block. The `coder_app` resource is defined to access `code-server` through
the dashboard UI over `localhost:13337`.
