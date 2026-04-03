#!/usr/bin/env python3
"""
Анализатор Telegram канала через юзербот (Telethon).
Читает посты И комментарии. Выдаёт полный отчёт.

Использование:
  python3 skills/channel-analyzer/scripts/analyze-channel.py --channel "{{TELEGRAM_CHANNEL}}" --days 7
  python3 skills/channel-analyzer/scripts/analyze-channel.py --channel "{{PAID_CHANNEL_ID}}" --days 30
  python3 skills/channel-analyzer/scripts/analyze-channel.py --channel "{{PAID_CHANNEL_ID}}" --days 30 --comments
"""

import asyncio
import argparse
import os
import sys
import datetime
import json

SESSION = os.path.expanduser("~/.openclaw/tg-stats-session")
API_ID = 30942990
API_HASH = "53e56f4eb2ed7134dc731a78238a7165"


async def main():
    parser = argparse.ArgumentParser(description="Telegram Channel Analyzer")
    parser.add_argument("--channel", required=True, help="Channel username (@name) or ID (-100...)")
    parser.add_argument("--days", type=int, default=7, help="Analyze last N days (default: 7)")
    parser.add_argument("--comments", action="store_true", default=True, help="Include comments (default: True)")
    parser.add_argument("--no-comments", action="store_true", help="Skip comments")
    parser.add_argument("--limit", type=int, default=100, help="Max posts to fetch (default: 100)")
    parser.add_argument("--format", choices=["text", "json"], default="text", help="Output format")
    args = parser.parse_args()

    if args.no_comments:
        args.comments = False

    from telethon import TelegramClient

    client = TelegramClient(SESSION, API_ID, API_HASH)
    await client.connect()

    if not await client.is_user_authorized():
        print("ERROR: Telethon session not authorized. Run auth first.", file=sys.stderr)
        sys.exit(1)

    # Resolve channel
    channel_id = args.channel
    if channel_id.startswith("-100") or channel_id.lstrip("-").isdigit():
        entity = await client.get_entity(int(channel_id))
    else:
        entity = await client.get_entity(channel_id)

    channel_title = entity.title if hasattr(entity, "title") else str(entity)
    print(f"📊 Анализ канала: {channel_title}")
    print(f"📅 Период: последние {args.days} дней")
    print(f"💬 Комментарии: {'да' if args.comments else 'нет'}")
    print("=" * 60)

    from_date = datetime.datetime.now(datetime.timezone.utc) - datetime.timedelta(days=args.days)

    # Fetch messages
    all_messages = await client.get_messages(entity, limit=args.limit)
    posts = [m for m in all_messages if m.date and m.date >= from_date]
    posts = list(reversed(posts))  # chronological order

    total_views = 0
    total_reactions = 0
    total_forwards = 0
    total_comments_count = 0
    posts_data = []

    for post in posts:
        text = (post.text or "")[:500]
        views = post.views or 0
        forwards = post.forwards or 0
        total_views += views
        total_forwards += forwards

        # Reactions
        react_count = 0
        react_details = []
        if post.reactions and post.reactions.results:
            for r in post.reactions.results:
                react_count += r.count
                emoji = r.reaction.emoticon if hasattr(r.reaction, 'emoticon') else '?'
                react_details.append(f"{emoji}:{r.count}")
        total_reactions += react_count

        # Media type
        media_type = ""
        if post.media:
            media_type = type(post.media).__name__.replace("MessageMedia", "")
        if post.file and post.file.name:
            media_type += f" [{post.file.name}]"

        date_str = post.date.strftime("%Y-%m-%d %H:%M")

        post_info = {
            "id": post.id,
            "date": date_str,
            "text": text,
            "views": views,
            "reactions": react_count,
            "reaction_details": ", ".join(react_details),
            "forwards": forwards,
            "media": media_type,
            "comments": []
        }

        # Fetch comments if enabled
        if args.comments and post.replies and post.replies.replies > 0:
            try:
                replies = await client.get_messages(entity, reply_to=post.id, limit=50)
                comments_texts = []
                for reply in reversed(replies):
                    if reply.text:
                        sender_name = ""
                        if reply.sender:
                            sender_name = getattr(reply.sender, 'first_name', '') or getattr(reply.sender, 'title', '') or ''
                        reply_date = reply.date.strftime("%m-%d %H:%M") if reply.date else ""
                        comments_texts.append({
                            "sender": sender_name,
                            "date": reply_date,
                            "text": reply.text[:300]
                        })
                post_info["comments"] = comments_texts
                total_comments_count += len(comments_texts)
            except Exception as e:
                post_info["comments_error"] = str(e)

        posts_data.append(post_info)

        # Pause to avoid flood
        await asyncio.sleep(0.3)

    await client.disconnect()

    # Output
    if args.format == "json":
        output = {
            "channel": channel_title,
            "period_days": args.days,
            "total_posts": len(posts_data),
            "total_views": total_views,
            "total_reactions": total_reactions,
            "total_forwards": total_forwards,
            "total_comments": total_comments_count,
            "avg_views": round(total_views / len(posts_data)) if posts_data else 0,
            "posts": posts_data
        }
        print(json.dumps(output, ensure_ascii=False, indent=2))
    else:
        # Text output
        print(f"\n📈 СВОДКА:")
        print(f"  Постов: {len(posts_data)}")
        print(f"  Просмотров всего: {total_views:,}")
        print(f"  Среднее просмотров: {round(total_views / len(posts_data)):,}" if posts_data else "  Среднее: -")
        print(f"  Реакций всего: {total_reactions}")
        print(f"  Пересылок: {total_forwards}")
        print(f"  Комментариев: {total_comments_count}")
        print("=" * 60)

        for p in posts_data:
            print(f"\n--- #{p['id']} | {p['date']} | 👁 {p['views']} | ❤️ {p['reactions']} | 🔄 {p['forwards']} ---")
            if p['media']:
                print(f"  📎 {p['media']}")
            if p['text']:
                print(f"  {p['text'][:250]}")
            if p.get('reaction_details'):
                print(f"  Реакции: {p['reaction_details']}")
            if p['comments']:
                print(f"  💬 {len(p['comments'])} комментариев:")
                for c in p['comments']:
                    sender = c['sender'] or 'Аноним'
                    print(f"    [{c['date']}] {sender}: {c['text'][:150]}")


if __name__ == "__main__":
    asyncio.run(main())
