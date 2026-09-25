---
title: DSH Memory and Session Restore Findings
type: note
permalink: jc-resoruse/investigation/dsh-memory-and-session-restore-findings
tags:
- dsh
- sessions
- memory
- basic-memory
- investigation
---

## Observations
- [fact] WorkBuddy memory library lives at `D:\JC_resoruse_demo\.workbuddy-ai\memory\` (16 files, 8 days of logs 09-14 → 09-21). `.workbuddy\memory` is a junction to it, not a copy
- [fact] That library is WorkBuddy's, NOT DSH's — DSH does not read it
- [fact] DSH has no built-in memory plugin at all; no `dsh-memory` package exists among the 300+ DSH packages. Only `dsh-mcp-client` bridges third-party memory MCP servers
- [fact] DSH session logs live at `~\.dsh\sessions\--D-JC_resoruse_demo--\<session-id>\session.v3.jsonl.zstd`, zstd-compressed multi-frame streams
- [fact] Session index at `~\.dsh\storages\workspace.json`; readable projections at `~\.dsh\storages\session_projcache\sessions\<id>.json`
- [session] `session-991576ac-6d50-44cc-a807-429183c1837a` = "安装 dsh marker", 16 turns / 575 events / 452 KB, intact
- [session] `session-f5a15166-5a69-444c-ae62-81e67e75f51f` = "查看记忆文件缺少存档问题", current session, intact
- [state] `archivedSessionIds: []` — nothing archived, nothing lost; both sessions restorable
- [decode] Reading `.zstd` session logs needs a multi-frame decoder (`zstd.ZstdDecompressor().stream_reader`); a single `decompress()` call silently yields only the first frame (~1 event)
- [tooling] `zstandard` installed into `C:\Users\Administrator\AppData\Roaming\uv\tools\basic-memory\Scripts\python.exe` for decoding
- [bug] `Start-Process` fails on this box with "Item has already been added. Key in dictionary: 'HTTP_PROXY' Key being added: 'http_proxy'" — use Python subprocess instead

## Relations
- relates_to [[DSH Memory Plugin Setup]]
- relates_to [[DSH Harness]]
