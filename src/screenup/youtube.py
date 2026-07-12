from __future__ import annotations

import re
from dataclasses import dataclass
from urllib.parse import urlparse, parse_qs


YOUTUBE_ID_PATTERN = re.compile(r"^[a-zA-Z0-9_-]{11}$")


@dataclass(frozen=True)
class YouTubeUrl:
    original_url: str
    video_id: str


def _normalized_host(hostname: str) -> str:
    return hostname.removeprefix("www.").lower()


def _extract_video_id(raw_url: str) -> str | None:
    parsed = urlparse(raw_url.strip())
    host = _normalized_host(parsed.hostname or "")

    if parsed.scheme not in {"http", "https"}:
        return None

    if host == "youtu.be":
        return next((part for part in parsed.path.split("/") if part), None)

    if host not in {"youtube.com", "m.youtube.com", "music.youtube.com"}:
        return None

    if parsed.path == "/watch":
        return parse_qs(parsed.query).get("v", [None])[0]

    parts = [part for part in parsed.path.split("/") if part]

    if len(parts) >= 2 and parts[0] in {"shorts", "embed", "live"}:
        return parts[1]

    return None


def parse_youtube_url(raw_url: str) -> YouTubeUrl:
    video_id = _extract_video_id(raw_url)

    if not video_id or not YOUTUBE_ID_PATTERN.match(video_id):
        raise ValueError("Cole uma URL valida do YouTube.")

    return YouTubeUrl(original_url=raw_url.strip(), video_id=video_id)
