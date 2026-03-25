# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is an autonomous AI agent project powered by [thepopebot](https://github.com/stephengpope/thepopebot). It uses a two-layer architecture:

1. **Event Handler** — A Next.js server (baked into Docker image) that orchestrates: web UI, Telegram chat, cron scheduling, webhook triggers, and job creation
2. **Docker Agent** — A container that runs the coding agent for autonomous task execution (each job gets its own branch, container, and PR)

**Key insight**: All core logic lives in the `thepopebot` npm package. This project contains only configuration, data, and skills. The Next.js app and `.next` build output are baked into the Docker image — they do not exist locally.

## Commands

```bash
# Development
npm run dev              # Start Next.js dev server with turbopack

# Build & Production
npm run build            # Build Next.js app
npm run start            # Start production server

# Setup
npm run setup            # Run thepopebot setup
npm run setup-telegram   # Configure Telegram webhook
npm run setup-weather    # Configure weather webhook
npm run reset-auth       # Reset authentication

# Deployment
npx thepopebot upgrade   # Upgrade to latest thepopebot version
```

## Architecture

```
┌─────────────────┐      ┌──────────────┐      ┌─────────────────┐
│  Event Handler  │ ───► │    GitHub    │ ───► │  Docker Agent   │
│  (Next.js)      │      │ (job/* branch│      │  (runs agent)   │
└────────▲────────┘      └──────┬───────┘      └────────┬────────┘
         │                      │                       │
         │                      │◄──────────────────────┘
         │                      │   (PR created)
         └──────────────────────┘
```

### Job Lifecycle
1. Job created via chat, cron, trigger, or API
2. `job/<uuid>` branch created with `logs/<uuid>/job.md` containing the task
3. `run-job.yml` workflow triggers on branch creation
4. Docker agent clones branch, runs the agent, logs to `logs/<uuid>/`
5. Agent commits results and opens a PR
6. `auto-merge.yml` squash-merges if changes within `ALLOWED_PATHS`
7. Notification sent back to event handler

## Key Directories

| Path | Purpose |
|------|---------|
| `config/` | User-editable agent configuration (prompts, crons, triggers) |
| `skills/` | Available skills; activate by symlinking to `skills/active/` |
| `cron/` | Shell scripts for command-type cron actions |
| `triggers/` | Scripts for command-type trigger actions |
| `logs/` | Per-job output (`logs/<JOB_ID>/job.md` + session `.jsonl`) |
| `data/` | SQLite database (`thepopebot.sqlite`) and cluster data |

## Configuration Files

| File | Purpose |
|------|---------|
| `config/SOUL.md` | Agent personality and values |
| `config/CRONS.json` | Scheduled job definitions |
| `config/TRIGGERS.json` | Webhook trigger definitions |
| `config/JOB_PLANNING.md` | Event handler LLM system prompt |
| `config/JOB_AGENT.md` | Docker agent runtime docs |

Config markdown files support template variables:
- `{{ filepath.md }}` — Include another file
- `{{datetime}}` — Current ISO timestamp
- `{{skills}}` — Dynamic list of active skills

## Action Types

| Type | LLM? | Use Case |
|------|------|----------|
| `agent` | Yes | Tasks that need to think, reason, write code |
| `command` | No | Shell scripts, file operations |
| `webhook` | No | Call external APIs, forward webhooks |

## Managed Files (Do Not Edit)

These are auto-synced by `thepopebot init` and `thepopebot upgrade`:
- `.github/workflows/`
- `docker-compose.yml`
- `.dockerignore`
- `.gitignore`
- `CLAUDE.md` (this file)

For Docker Compose customization, use `docker-compose.custom.yml` and set `COMPOSE_FILE=docker-compose.custom.yml` in `.env`.

## Skills

Skills in `skills/` are activated by symlinking into `skills/active/`. Both `.pi/skills` and `.claude/skills` point to `skills/active/`.

To create a skill:
1. Create directory in `skills/` with a `SKILL.md` (frontmatter: name, description, userInvokeable)
2. Add executable scripts or JS files
3. Symlink: `ln -s ../your-skill skills/active/your-skill`

## Database

SQLite via Drizzle ORM at `data/thepopebot.sqlite`. Auto-initialized and migrated on startup. Tables: `users`, `chats`, `messages`, `notifications`, `subscriptions`, `settings`.

## Authentication

NextAuth v5 with Credentials provider. First visit creates admin account. API routes use `x-api-key` header (keys generated via web UI).

## GitHub Secrets

| Prefix | Visible to LLM? |
|--------|-----------------|
| `AGENT_` | No (filtered) |
| `AGENT_LLM_` | Yes |

## Environment Variables

Required: `APP_URL`, `AUTH_SECRET`, `GH_TOKEN`, `GH_OWNER`, `GH_REPO`

Optional: `TELEGRAM_BOT_TOKEN`, `TELEGRAM_CHAT_ID`, `LLM_PROVIDER`, `LLM_MODEL`, `WEB_SEARCH`, `AGENT_BACKEND`

## Important Constraints

- The Next.js app code doesn't exist locally — it's in the npm package
- When running locally with `npm run dev`, you're running the Next.js app from the package
- Changes to managed files will be overwritten on upgrade
- For production, use Docker Compose (the Next.js app runs inside the container)
