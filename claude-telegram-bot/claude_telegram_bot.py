#!/usr/bin/env python3
"""Telegram bot that bridges messages to a persistent Claude Code session.

Usage:
    export TELEGRAM_BOT_TOKEN="your-token"
    export TELEGRAM_ALLOWED_CHAT_IDS="123456789"  # optional

    # Point at any project directory:
    python3 claude_telegram_bot.py /path/to/your/project

    # Or use current directory:
    python3 claude_telegram_bot.py
"""

import argparse
import os
import sys
import subprocess
import logging
from pathlib import Path
from telegram import Update
from telegram.ext import Application, CommandHandler, MessageHandler, filters, ContextTypes

logging.basicConfig(level=logging.INFO, format="%(asctime)s %(levelname)s %(message)s")
logger = logging.getLogger(__name__)

BOT_TOKEN = os.environ.get("TELEGRAM_BOT_TOKEN")
ALLOWED_CHAT_IDS = os.environ.get("TELEGRAM_ALLOWED_CHAT_IDS", "")

if not BOT_TOKEN:
    print("Set TELEGRAM_BOT_TOKEN environment variable")
    sys.exit(1)

allowed_ids = set()
if ALLOWED_CHAT_IDS.strip():
    allowed_ids = {int(x.strip()) for x in ALLOWED_CHAT_IDS.split(",") if x.strip()}

# Per-chat state: project dir and whether conversation has started
chat_state: dict[int, dict] = {}

# Default project directory (set via CLI arg)
DEFAULT_PROJECT_DIR: str = "."


def is_allowed(chat_id: int) -> bool:
    return not allowed_ids or chat_id in allowed_ids


def get_state(chat_id: int) -> dict:
    if chat_id not in chat_state:
        chat_state[chat_id] = {"project": DEFAULT_PROJECT_DIR, "started": False}
    return chat_state[chat_id]


async def start(update: Update, context: ContextTypes.DEFAULT_TYPE):
    chat_id = update.effective_chat.id
    state = get_state(chat_id)
    await update.message.reply_text(
        f"Claude Code bridge active.\n"
        f"Chat ID: `{chat_id}`\n"
        f"Project: `{state['project']}`\n\n"
        f"Commands:\n"
        f"/project <path> — switch project directory\n"
        f"/reset — new conversation\n"
        f"/status — show current state",
        parse_mode="Markdown",
    )


async def reset(update: Update, context: ContextTypes.DEFAULT_TYPE):
    chat_id = update.effective_chat.id
    state = get_state(chat_id)
    state["started"] = False
    await update.message.reply_text(
        f"Conversation reset. Project still: `{state['project']}`",
        parse_mode="Markdown",
    )


async def set_project(update: Update, context: ContextTypes.DEFAULT_TYPE):
    chat_id = update.effective_chat.id
    if not is_allowed(chat_id):
        return

    args = context.args
    if not args:
        await update.message.reply_text("Usage: /project /path/to/your/repo")
        return

    path = " ".join(args)
    resolved = str(Path(path).expanduser().resolve())

    if not Path(resolved).is_dir():
        await update.message.reply_text(f"Not a directory: `{resolved}`", parse_mode="Markdown")
        return

    state = get_state(chat_id)
    state["project"] = resolved
    state["started"] = False  # reset conversation for new project
    await update.message.reply_text(
        f"Project set to: `{resolved}`\nConversation reset.",
        parse_mode="Markdown",
    )


async def status(update: Update, context: ContextTypes.DEFAULT_TYPE):
    chat_id = update.effective_chat.id
    state = get_state(chat_id)
    await update.message.reply_text(
        f"Project: `{state['project']}`\n"
        f"Conversation active: {state['started']}",
        parse_mode="Markdown",
    )


async def handle_message(update: Update, context: ContextTypes.DEFAULT_TYPE):
    chat_id = update.effective_chat.id
    if not is_allowed(chat_id):
        await update.message.reply_text(f"Unauthorized. Chat ID: {chat_id}")
        return

    user_text = update.message.text
    if not user_text:
        return

    state = get_state(chat_id)
    sent = await update.message.reply_text("thinking...")

    cmd = ["claude", "-p", "--output-format", "text"]
    if state["started"]:
        cmd.append("--continue")
    cmd.append(user_text)

    try:
        result = subprocess.run(
            cmd,
            capture_output=True,
            text=True,
            timeout=300,
            cwd=state["project"],
        )
        response = result.stdout.strip() or result.stderr.strip() or "(empty response)"
        state["started"] = True

        await sent.delete()
        for i in range(0, len(response), 4000):
            await update.message.reply_text(response[i:i + 4000])

    except subprocess.TimeoutExpired:
        await sent.edit_text("Claude timed out (5 min limit).")
    except Exception as e:
        await sent.edit_text(f"Error: {e}")


def main():
    global DEFAULT_PROJECT_DIR

    parser = argparse.ArgumentParser(description="Claude Code Telegram bridge")
    parser.add_argument("project_dir", nargs="?", default=".",
                        help="Default project directory for Claude to work in")
    args = parser.parse_args()

    DEFAULT_PROJECT_DIR = str(Path(args.project_dir).expanduser().resolve())
    if not Path(DEFAULT_PROJECT_DIR).is_dir():
        print(f"Not a directory: {DEFAULT_PROJECT_DIR}")
        sys.exit(1)

    logger.info(f"Default project: {DEFAULT_PROJECT_DIR}")

    app = Application.builder().token(BOT_TOKEN).build()
    app.add_handler(CommandHandler("start", start))
    app.add_handler(CommandHandler("reset", reset))
    app.add_handler(CommandHandler("project", set_project))
    app.add_handler(CommandHandler("status", status))
    app.add_handler(MessageHandler(filters.TEXT & ~filters.COMMAND, handle_message))

    logger.info("Bot started. Waiting for messages...")
    app.run_polling()


if __name__ == "__main__":
    main()
