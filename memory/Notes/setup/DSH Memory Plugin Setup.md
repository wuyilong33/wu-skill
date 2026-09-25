---
title: DSH Memory Plugin Setup
type: note
permalink: jc-resoruse/setup/dsh-memory-plugin-setup
tags:
- dsh
- memory-plugin
- basic-memory
- setup
---

## Observations
- [setup] Installed via `uv tool install basic-memory --prerelease=allow` (basic-memory 0.23.2, FastMCP 4.0.0b1)
- [config] Registered in DSH as `@deepseek-ai/dsh-mcp-client` with `serverName: memory` → tools appear as `mcp__memory__*`
- [config] DSH profile patch: `C:\Users\Administrator\.dsh\profiles\web\cordis.patch.yml`
- [project] Basic Memory project `jc-resoruse` → `D:\JC_resoruse_demo\.dsh-memory`
- [pitfall] `semantic_search_enabled` set to `false` because the only vector backends are pgvector/milvus and the local PGVector on port 5432 is not running — leaving it on hangs MCP startup
- [bug] Startup crash root cause: inherited `NO_PROXY` ends with the URL-style token `[::1]`, which bundled `httpx2` parses as a port → `InvalidURL: Invalid port: ':1]'`. FastMCP's PyPI version check runs during the stdio banner *before* the MCP handshake, so the server died with no protocol response. Fixed by overriding `NO_PROXY`/`no_proxy` in the plugin `env` to `localhost,127.0.0.1,::1`
- [env] DSH has no built-in memory plugin; persistence is session logs (`~/.dsh/sessions/**/session.v3.jsonl.zstd`) plus optional `AGENTS.md` instruction files

## Relations
- relates_to [[DSH Harness]]
- relates_to [[JC_resoruse_demo]]
