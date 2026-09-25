# Installed DSH plugins on this machine
#
# Source of truth: ~/.dsh/profiles/desktop/package.json
# Profile: desktop (the DeepSeek Harness desktop launcher always uses this one;
# the profile path is hardcoded in apps/desktop/src/paths.ts).
#
# Restore with:  bash scripts/install-plugins.sh <profile-dir>

## Official DSH bundles (shipped with the harness, not installed separately)

| Bundle | Notes |
| --- | --- |
| `@deepseek-ai/dsh-base` | Core. Always present. |
| `@deepseek-ai/dsh-web-app` | Web UI layer. Always present. |
| `@deepseek-ai/dsh-experimental-agent-team-profile` | Agent Teams — official. |
| `@deepseek-ai/dsh-experimental-agent-team-web-profile` | Agent Teams web surface — official. |

## Third-party plugins (installed by the user)

| npm package | Version | Upstream | What it does |
| --- | --- | --- | --- |
| `@linxin666/dsh-web-all` | 0.3.24 | https://github.com/zhu1090093659/dsh-web | Bundle of 20 DSH web plugins: task board, git graph, skill explorer, skin center, remote web UI, SSH, pet, usage, session archive, doctor, i18n, model capabilities, preset center, plugin manager, market, community plugins, better sidebar. |
| `@liustack/modsearch` | 5.10.3 | https://github.com/liustack/modsearch | Web search / X search / page fetch for models without native web access. MCP-based. |
| `@roarpeng/graphflow` | 1.25.1 | https://github.com/Roarpeng/GraphFlow | Local-first code knowledge graph + context harness. Exposes `mcp__graphflow__*` tools. |
| `dshmarket` | 1.51.0 | https://github.com/dsh-market/dsh-market | In-harness plugin marketplace UI. |

### Plugins that ship dependencies of `@linxin666/dsh-web-all`

These are pulled in automatically — listed for reference, do not install directly:

`dsh-client-ui-plugin-manager`, `dsh-client-ui-community-plugins`,
`dsh-client-ui-market`, `dsh-client-ui-task-board`, `dsh-client-ui-git-graph`,
`dsh-pet`, `dsh-remote-web-ui`, `dsh-ssh`, `dsh-tool-describe-image`,
`dsh-liangshen`, `dsh-client-ui-skill-explorer`, `dsh-doctor`, `dsh-usage`,
`dsh-session-archive`, `dsh-client-ui-model-capabilities`,
`dsh-client-ui-preset-center`, `dsh-client-ui-web-ui-settings`,
`dsh-client-ui-skin-center`, `dsh-i18n`, `dsh-better-sidebar`

## Native dependencies requiring build approval

Installing these plugins pulls native modules whose build scripts pnpm blocks
by default. On a fresh machine, pnpm will print them and write placeholders
into `pnpm-workspace.yaml` under `allowBuilds`. Set them to `true` and re-run
`pnpm install`:

| Package | Why it needs a build |
| --- | --- |
| `node-pty` | Pseudo-terminals — used by the SSH / web-terminal plugin |
| `better-sqlite3` | SQLite binding — used by GraphFlow storage |
| `onnxruntime-node` | Local embeddings for GraphFlow |
| `sharp` | Image processing |
| `cloudflared` | Tunnel binary download |
| `cpu-features`, `ssh2` | SSH crypto (both have pure-JS fallbacks) |

**Note:** `cpu-features` and `ssh2`'s native crypto binding fail to compile
without a C++ toolchain and Python. This is **not fatal** — `ssh2` falls back
to pure JavaScript, and `node-pty` / `better-sqlite3` ship prebuilt binaries
that work without any compiler.
