---
name: daily-news
description: Fetches and summarizes the top AI/tech news stories
---

# Daily AI/Tech News

Get the latest AI and tech news summaries from Hacker News.

## Usage

```bash
skills/daily-news/news.sh
```

Fetches the top stories from Hacker News, filters for AI/tech-related content, and outputs a formatted summary of the top 3 stories.

## Output Format

```
# Top AI/Tech News - 2026-03-20

## 1. [Story Title](https://link)
Score: 123 points
Comments: 45

## 2. [Story Title](https://link)
Score: 98 points
Comments: 23

## 3. [Story Title](https://link)
Score: 76 points
Comments: 12

---
Fetched 50 stories, found 15 AI/tech related stories
```

## How It Works

1. Fetches the top 50 story IDs from Hacker News API
2. Retrieves details for each story
3. Filters for AI/tech-related stories using keywords (AI, machine learning, neural, tech, etc.)
4. Sorts by score and displays the top 3
5. Includes metadata (score, comments, links)

## Error Handling

The script includes error handling for:
- Network failures (curl errors)
- Invalid JSON responses
- Empty results
- Missing required data fields

## Requirements

- `curl` - For fetching data from Hacker News API
- `jq` - For JSON parsing (optional, script uses sed/grep as fallback)
- `grep` - For filtering stories by keywords

## When to Use

- Daily news summaries for AI/tech updates
- Monitoring trending topics
- Quick news briefing
- Researching current tech discussions
