# config/ — Agent Configuration

This directory contains all user-editable configuration files. These files are **not managed** — your changes are preserved across upgrades.

## File Reference

### System Prompts

| File | Used By | Purpose |
|------|---------|---------|
| `agent-chat/SYSTEM.md` | Event handler | System prompt for the agent chat (job planning from web/Telegram). |
| `code-chat/SYSTEM.md` | Code workspaces | System prompt for the planning chat in interactive code workspaces. |
| `agent-job/SOUL.md` | Docker agent | Agent personality, identity, and values. Included in agent job system prompts. |
| `agent-job/AGENT_JOB.md` | Docker agent | Runtime environment documentation injected into the agent's context. |
| `agent-job/SUMMARY.md` | Docker agent | Prompt template for summarizing completed job results. |
| `cluster/SYSTEM.md` | Cluster workers | Shared system prompt for all cluster worker agents. |
| `cluster/ROLE.md` | Cluster workers | Per-role prompt template (receives role-specific variables). |
| `HEARTBEAT.md` | Heartbeat cron | Self-monitoring prompt for the agent's periodic heartbeat job. |

### Scheduling & Triggers

| File | Purpose |
|------|---------|
| `CRONS.json` | Scheduled job definitions — loaded at server startup by `node-cron`. |
| `TRIGGERS.json` | Webhook trigger definitions — loaded at server startup. |

## Template Variables

Config markdown files support includes and built-in variables (processed by `render-md.js` at runtime):

| Syntax | Description |
|--------|-------------|
| `{{ filepath.md }}` | Include another file (path relative to project root, recursive with circular detection) |
| `{{datetime}}` | Current ISO timestamp |
| `{{skills}}` | Dynamic bullet list of active skill descriptions from `skills/active/*/SKILL.md` frontmatter |

## When Changes Take Effect

- **Prompt files** (`.md`) — Changes take effect immediately on the next LLM call. No restart needed.
- **CRONS.json / TRIGGERS.json** — Require a server restart to reload schedules and trigger watchers.
