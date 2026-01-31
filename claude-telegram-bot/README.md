# Claude Telegram Bot

A Telegram bot that bridges your phone to a persistent Claude Code session, letting you interact with any project from anywhere.

## Setup

### 1. Create a Telegram Bot

1. Open Telegram, message [@BotFather](https://t.me/BotFather)
2. Send `/newbot`, follow the prompts
3. Copy the bot token

### 2. Install

If using the dotfiles installer:

```bash
./install.sh  # installs python-telegram-bot automatically
```

Or manually:

```bash
pip3 install python-telegram-bot
```

### 3. Set Environment Variables

```bash
export TELEGRAM_BOT_TOKEN="your-bot-token-here"

# Optional: restrict to your chat ID only (recommended)
export TELEGRAM_ALLOWED_CHAT_IDS="123456789"
```

Add these to your `.bashrc` or `.env` to persist them.

> To find your chat ID, start the bot without `TELEGRAM_ALLOWED_CHAT_IDS` and send `/start`. It will display your chat ID.

## Usage

```bash
# Start the bot pointed at a project
claude-bot /path/to/your/project

# Or use current directory
claude-bot
```

Then open Telegram and message your bot.

## Telegram Commands

| Command | Description |
|---------|-------------|
| `/start` | Show bot info and your chat ID |
| `/project /path/to/repo` | Switch to a different project directory |
| `/reset` | Start a new conversation (keeps the same project) |
| `/status` | Show current project and conversation state |

## How It Works

Every text message you send gets forwarded to `claude -p` running inside the project directory. The bot uses `--continue` to maintain conversation history, so Claude remembers previous messages and can build on earlier work.

```
Phone (Telegram) --> Bot --> claude -p --continue "your message"
                                     |
                                     v
                              Project directory
                              (reads/edits files,
                               runs commands, etc.)
```

Claude has full access to the project: it can read files, edit code, run tests, and execute commands — just like an interactive Claude Code session.

## Example Session

```
You:    what does this project do?
Claude: This is a Next.js app that...

You:    find all TODO comments
Claude: Found 3 TODOs: ...

You:    fix the bug in src/utils.ts where it doesn't handle null
Claude: I've updated src/utils.ts to add a null check...

You:    /project ~/projects/other-repo
Bot:    Project set to: /home/user/projects/other-repo

You:    run the tests
Claude: Running pytest... 12 passed, 0 failed.
```

## Security

- Set `TELEGRAM_ALLOWED_CHAT_IDS` to lock the bot to your account only
- Without it, anyone who discovers your bot can run Claude commands on your machine
- The bot token is a secret — don't commit it to version control
