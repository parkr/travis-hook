# travis-hook

A GitHub webhook. Webhook triggers an empty commit to a series of repos.

## Setup

I'm using capistrano for deployment, so setup is pretty easy. Create the
following files:

- `shared/config/repos.yml`
- `shared/config/secrets.yml`
- `shared/config/sidekiq.yml`

### `repos.yml`

`repos.yml` should contain a hash of repos:

```yaml
---
"https://username:password@github.com/owner/repo-to-write-to.git": "owner/repo-to-write-to"
```

These will be iterated over, cloned, updated, committed to, and updated on
the destination server (e.g. github.com).

### `sidekiq.yml`

`sidekiq.yml` contains any and all of your Sidekiq configuration options.

### `secrets.yml`

`secrets.yml` contains an array of accepted secret keys. The hook will
authenticate against these and return a 401 if a key is sent that isn't
there.
