# DSH config bundle

A portable copy of a working **DeepSeek Harness** setup: skills, agent
instructions, plugin list, and the `/wuai` workflow. Built so a second machine
can be brought to the same configuration without rediscovering any of it.

## What is in here

```
skills/          29 skills, ready to drop into ~/.dsh/skills/
references/      7 shared reference docs (referenced by some skills)
config/          AGENTS.md, cordis.patch.yml, pet/skin state, settings template
plugins/         PLUGINS.md — the plugin list with upstream sources
scripts/         restore.sh, install-plugins.sh
wuai/            the /wuai workflow skill (also standalone)
```

## Quick restore on a new machine

**1. Install DeepSeek Harness and start it once**, so `~/.dsh` and its profiles
are created. Then close it.

**2. Clone this repository.**

```bash
git clone git@github.com:wuyilong33/wu-skill.git dsh-config
cd dsh-config
```

**3. Preview what will be copied** (changes nothing):

```bash
bash scripts/restore.sh
```

**4. Apply it:**

```bash
bash scripts/restore.sh --apply
```

This copies the skills, the shared references, and `AGENTS.md` into `~/.dsh`.
It **skips `settings.yaml` if one already exists** and never touches
credentials.

**5. Install the plugins:**

```bash
bash scripts/install-plugins.sh ~/.dsh/profiles/desktop
```

Then follow the printed instructions to (a) approve the native build scripts
and (b) add the bundle entries to the profile's `package.json`.

**6. Reconfigure the model provider.**

`settings.yaml` is **not** portable — it points at a local proxy on
`127.0.0.1:8787` that only exists on the original machine. Use
`config/settings.template.yaml` as a starting point and set your own endpoint
and key. Keys live in environment variables, never in the file.

**7. Restart DeepSeek Harness.**

## The `/wuai` workflow

A single command that runs a multi-agent pipeline instead of improvising:

```
/wuai <what you want built or analyzed>
```

Six phases: reconnaissance → **consumer analysis** → architect (spec +
`path:line` anchors) → parallel execution with per-unit verification →
**convergence check** → independent read-only audit.

The consumer-analysis phase exists because a bug is rarely where it appears:
naming what is consumed, who reads it, and which reader is actually broken
prevents fixing the wrong place. The convergence check exists because a fix
that works while making the codebase worse is not finished.

See [wuai/SKILL.md](wuai/SKILL.md).

## Deliberately excluded

These are **not** in this repository, on purpose:

| Excluded | Why |
| --- | --- |
| `.credentials.yaml` | Holds secrets. Recreate via the GUI Models page. |
| `sessions/`, `storages/` | Conversation history and caches — machine-specific, and may contain private content. |
| `profiles/*/node_modules` | Rebuilt by the install script. |
| SSH private keys | Never leave the machine that owns them. |

## A note on the network

On the source machine, `github.com`'s IP was blocked, which broke HTTPS git
and `gh auth login`. The working configuration routes SSH over port 443:

```
# ~/.ssh/config
Host github.com
  HostName ssh.github.com
  Port 443
  User git
  IdentityFile ~/.ssh/id_ed25519_wuai
  IdentitiesOnly yes
```

If `git push` fails on the new machine with a connection timeout rather than an
auth error, this is the fix — and the same IP may not be blocked there at all,
in which case it is unnecessary.

## Skills inventory

**Matt Pocock's engineering skills** (MIT) — 22 of them, including `diagnose`,
`tdd`, `triage`, `to-prd`, `to-issues`, `grill-me`, `zoom-out`,
`ubiquitous-language`, `improve-codebase-architecture`, `write-a-skill`,
`caveman`.

**Addy Osmani's skills** (MIT) — `spec-driven-development`,
`planning-and-task-breakdown`, `code-review-and-quality`,
`incremental-implementation`, `context-engineering`.

**From TerminalSkills** (Apache-2.0) — `bug-hunt-swarm`.

**`wuai`** — the workflow in this repository.

Each skill keeps its own licence; see the individual `SKILL.md` files.

## License

MIT for the content authored here; third-party skills retain their own licences.
