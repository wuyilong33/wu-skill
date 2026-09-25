# Memory — JC_resoruse_demo

The `basic-memory` knowledge base from the source machine, packaged so a second
machine keeps the project notes.

## Contents

```
memory/
├── Notes/                     Markdown notes (portable, human-readable)
│   ├── investigation/DSH Memory and Session Restore Findings.md
│   └── setup/DSH Memory Plugin Setup.md
├── memory.db                  basic-memory SQLite database (572 KB)
└── config.template.json       project registry from the source machine
```

The database holds **2 entities and 18 observations** — verified by query:

```sql
SELECT COUNT(*) FROM entity;        -- 2
SELECT COUNT(*) FROM observation;   -- 18
```

## Restore on a new machine

**1. Copy the notes into your project.**

```bash
mkdir -p /path/to/your/project/.dsh-memory
cp -r memory/Notes/. /path/to/your/project/.dsh-memory/
```

**2. Register the project with basic-memory.** Edit
`~/.basic-memory/config.json` (use `config.template.json` as a shape
reference) and point a project entry at your notes directory:

```json
{
  "projects": {
    "jc-resoruse": {
      "path": "/path/to/your/project/.dsh-memory",
      "mode": "local"
    }
  },
  "default_project": "jc-resoruse"
}
```

**Paths in the template are Windows paths from the source machine** — replace
them.

**3. Or skip the database and let basic-memory re-index.** Copying
`memory.db` preserves observation IDs and relations, but if you only need the
knowledge, the Markdown notes are self-sufficient: point basic-memory at
`Notes/` and it rebuilds the index.

## Why the GraphFlow graphs are NOT here

Two GraphFlow indexes existed on the source machine (41 MB combined). They are
deliberately excluded:

- **They contain conversation history, not just code.** Their nodes include
  `dialogue-session` and `Decision` entries holding `userQuery` text from past
  sessions.
- **One of them held a live API key in plain text.** A pasted credential had
  been captured as a query and stored verbatim. Publishing it would have leaked
  a working key.
- **They embed absolute paths** from the source machine, so they would be
  invalid on a different machine anyway.

Rebuild them locally instead — see the GraphFlow section of the repository
README.

## Secret scan performed

Before packaging, the notes and database were scanned for `sk-*`, `ghp_*`,
`Bearer` tokens, and private-key headers:

```
clean [sk-[a-zA-Z0-9]{16,}]
clean [ghp_[a-zA-Z0-9]{20,}]
clean [gho_[a-zA-Z0-9]{20,}]
clean [Bearer\s+[A-Za-z0-9._-]{20,}]
clean [-----BEGIN]
```

The single `token` match in the notes is the word `NO_PROXY`'s trailing token
in a bug description — a false positive, not a credential.
