{%- if salt.hashutil.github_signature(data['body'], salt.sdb.get('sdb://secrets/github-webhook'), data['headers']['X-Hub-Signature-256']) %}
update:
  caller.filesystem.update:
    - args: []

  caller.saltutil.sync_all:
    - args: []

  caller.state.apply:
    - args: []
{%- endif %}
