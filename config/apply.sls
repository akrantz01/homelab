{%- set body = data.body|load_json -%}
{%- if salt.hashutil.github_signature(data.body, salt.sdb.get('sdb://secrets/github-webhook'), data.headers['X-Hub-Signature-256']) and body.ref == "refs/heads/main" %}
update:
  caller.filesystem.update:
    - args: []

  caller.saltutil.sync_all:
    - args: []

  caller.state.apply:
    - args: []
{%- endif %}
