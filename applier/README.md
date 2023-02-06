# applier

Automatically apply SaltStack highstate on GitHub webhooks.


### Configuration

The following environment variables can be configured:

| Environment Variable       | Default        | Description                                                    |
|----------------------------|----------------|----------------------------------------------------------------|
| DEFAULT_BRANCH             | main           | The branch to perform updates on, typically the default branch |
| SECRET_TTL                 | 900            | How many seconds to cache secrets for                          |
| WEBHOOK_SECRET_SDB_KEY     | github-webhook | The SDB secret path to read from                               |
| WEBHOOK_SECRET_SDB_BACKEND | secrets        | The SDB secret backend to use                                  |
