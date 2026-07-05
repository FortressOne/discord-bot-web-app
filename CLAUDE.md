# Working in this repo

## Multiple Claude sessions share this checkout

More than one Claude session works in this repo at the same time, and they
share this checkout — so branches alone don't isolate them. Use git
worktrees:

- **This directory stays on master at all times.** It is the deploy tree:
  `kamal deploy` builds whatever is checked out HERE. Never switch this
  checkout to a feature branch and never leave uncommitted work in it.
- **Do feature work in a worktree on your own branch.** Existing:
  - `../discord-bot-web-app-stats` → branch `stats-browsing` (stats
    browsing / match pages session)
  - Create your own: `git worktree add ../discord-bot-web-app-<topic> -b <topic>`
  - Don't commit to another session's branch.
- **To ship:** merge your branch into master in THIS directory
  (`git merge --ff-only <branch>` when possible), run the deploy from
  here, then continue in your worktree.
- **Before deploying, check for a running backfill.** A deploy replaces the
  web container and kills any `stats:backfill` running inside it. Check:
  `ssh sheldon@sheldon-t470 'docker exec $(docker ps --format "{{.Names}}" | grep discord-bot-web-app-web | head -1) pgrep -af stats:backfill'`
  If one is running, either wait or restart it in the new container after
  deploying: `docker exec -d <container> bash -c "FORCE=1 nice -n 10 bin/rails stats:backfill > log/stats_backfill.log 2>&1"`
  (env var before `nice`; drop `FORCE=1` for a resumable non-force run).

## Deploy pipeline (from sheldon-desktop)

- Ruby via `mise exec ruby@3.2.2 --` (system ruby is wrong version).
- Secrets: `set -a; . ~/.kamal-env; set +a` first.
- Kamal's classic driver does not push with podman. Full sequence:
  `kamal build push`, then
  `podman push localhost/fortressone/discord-bot-web-app:<git-sha> docker.io/fortressone/discord-bot-web-app:<git-sha>`
  (and `:latest`), then `kamal deploy --skip-push`.
- TLS is a Cloudflare Origin cert fed through kamal secrets
  (`~/.kamal-origin.{crt,key}`); do NOT switch `proxy: ssl:` back to `true`
  (ACME cannot succeed here and it takes HTTPS down).

## Tests

`mise exec ruby@3.2.2 -- bin/rails test`
