#!/usr/bin/env python3
"""
hf-model-scout.py - Discover GGUF models on HuggingFace that fit your hardware

Usage:
    ./hf-model-scout.py                     # Show trending models (120GB default)
    ./hf-model-scout.py --max-size 80       # Custom max size in GB
    ./hf-model-scout.py --search qwen       # Search for models
    ./hf-model-scout.py --details MODEL_ID  # Show all quantizations
"""

import argparse
import asyncio
import json
import sys
from dataclasses import dataclass, field
from pathlib import Path
from typing import Optional
from urllib.parse import urlencode

# Use aiohttp if available, fallback to synchronous requests
import urllib.request

try:
    import aiohttp
    HAS_AIOHTTP = True
except ImportError:
    HAS_AIOHTTP = False

# Constants
HF_API_BASE = "https://huggingface.co/api/models"
DEFAULT_MAX_SIZE_GB = 120  # Strix Halo: 128GB UMA - 8GB system
DEFAULT_LIMIT = 30
DEFAULT_SORT = "likes7d"
MAX_CONCURRENT = 10

# Colors
RESET = "\033[0m"
RED = "\033[0;31m"
GREEN = "\033[0;32m"
YELLOW = "\033[1;33m"
CYAN = "\033[0;36m"
BOLD = "\033[1m"

# Quantization quality ratings
QUANT_QUALITY = {
    "Q8_0": "Excellent",
    "Q6_K": "Very Good",
    "Q5_K_M": "Good",
    "Q5_K_S": "Good",
    "Q4_K_M": "Decent",
    "Q4_K_S": "Decent",
    "Q3_K_M": "Fair",
    "Q3_K_L": "Fair",
    "Q3_K_XL": "Fair+",
    "IQ4_XS": "Good",
    "IQ3_M": "Fair",
}


@dataclass
class GGUFFile:
    name: str
    size: int  # bytes


@dataclass
class Model:
    id: str
    author: str = ""
    downloads: int = 0
    likes: int = 0
    architecture: str = ""
    context_length: int = 0
    files: list = field(default_factory=list)
    smallest_fit: Optional[GGUFFile] = None
    largest_fit: Optional[GGUFFile] = None
    error: Optional[str] = None


def format_size(bytes_size: int) -> str:
    """Format bytes as human-readable size."""
    gb = bytes_size / (1024 ** 3)
    if gb < 1:
        return f"{gb * 1024:.0f} MB"
    return f"{gb:.1f} GB"


def format_downloads(n: int) -> str:
    """Format download count."""
    if n >= 1_000_000:
        return f"{n / 1_000_000:.1f}M"
    if n >= 1_000:
        return f"{n / 1_000:.1f}K"
    return str(n)


async def fetch_json_async(session: "aiohttp.ClientSession", url: str) -> dict:
    """Fetch JSON from URL using aiohttp."""
    async with session.get(url) as resp:
        return await resp.json()


def fetch_json_sync(url: str) -> dict:
    """Fetch JSON from URL using urllib (fallback)."""
    req = urllib.request.Request(url, headers={"User-Agent": "hf-model-scout/1.0"})
    with urllib.request.urlopen(req, timeout=30) as resp:
        return json.loads(resp.read().decode())


async def fetch_models_async(session, sort_by: str, limit: int, search: str, author: str) -> list[dict]:
    """Fetch model list from HuggingFace API."""
    params = {
        "filter": "gguf",
        "pipeline_tag": "text-generation",
        "sort": sort_by,
        "direction": "-1",
        "limit": str(limit),
    }
    if search:
        params["search"] = search
    if author:
        params["author"] = author

    url = f"{HF_API_BASE}?{urlencode(params)}"
    return await fetch_json_async(session, url)


def fetch_models_sync(sort_by: str, limit: int, search: str, author: str) -> list[dict]:
    """Fetch model list (synchronous fallback)."""
    params = {
        "filter": "gguf",
        "pipeline_tag": "text-generation",
        "sort": sort_by,
        "direction": "-1",
        "limit": str(limit),
    }
    if search:
        params["search"] = search
    if author:
        params["author"] = author

    url = f"{HF_API_BASE}?{urlencode(params)}"
    return fetch_json_sync(url)


async def fetch_all_gguf_files_async(session, model_id: str) -> list[GGUFFile]:
    """Fetch all GGUF files including split files in subdirectories."""
    files = []

    # Fetch root tree
    url = f"{HF_API_BASE}/{model_id}/tree/main"
    try:
        entries = await fetch_json_async(session, url)
    except Exception:
        return files

    dirs = []
    for e in entries:
        if e.get("type") == "file" and e.get("path", "").endswith(".gguf"):
            files.append(GGUFFile(name=e["path"], size=e.get("size", 0)))
        elif e.get("type") == "directory":
            dirs.append(e["path"])

    # Check directories for split files (concurrently)
    async def check_dir(d: str):
        try:
            sub_url = f"{HF_API_BASE}/{model_id}/tree/main/{d}"
            sub_entries = await fetch_json_async(session, sub_url)
            total_size = 0
            has_gguf = False
            for e in sub_entries:
                if e.get("path", "").endswith(".gguf"):
                    total_size += e.get("size", 0)
                    has_gguf = True
            if has_gguf:
                return GGUFFile(name=Path(d).name + ".gguf", size=total_size)
        except Exception:
            pass
        return None

    # Fetch subdirectories concurrently
    results = await asyncio.gather(*[check_dir(d) for d in dirs])
    for r in results:
        if r:
            files.append(r)

    # Sort by size
    files.sort(key=lambda f: f.size)
    return files


def fetch_all_gguf_files_sync(model_id: str) -> list[GGUFFile]:
    """Fetch all GGUF files (synchronous fallback)."""
    files = []

    url = f"{HF_API_BASE}/{model_id}/tree/main"
    try:
        entries = fetch_json_sync(url)
    except Exception:
        return files

    dirs = []
    for e in entries:
        if e.get("type") == "file" and e.get("path", "").endswith(".gguf"):
            files.append(GGUFFile(name=e["path"], size=e.get("size", 0)))
        elif e.get("type") == "directory":
            dirs.append(e["path"])

    # Check directories for split files
    for d in dirs:
        try:
            sub_url = f"{HF_API_BASE}/{model_id}/tree/main/{d}"
            sub_entries = fetch_json_sync(sub_url)
            total_size = 0
            has_gguf = False
            for e in sub_entries:
                if e.get("path", "").endswith(".gguf"):
                    total_size += e.get("size", 0)
                    has_gguf = True
            if has_gguf:
                files.append(GGUFFile(name=Path(d).name + ".gguf", size=total_size))
        except Exception:
            pass

    files.sort(key=lambda f: f.size)
    return files


async def process_model_async(session, model_data: dict, max_size_bytes: int, semaphore) -> Model:
    """Process a single model to get file sizes."""
    async with semaphore:
        model = Model(
            id=model_data.get("id", ""),
            author=model_data.get("author", ""),
            downloads=model_data.get("downloads", 0),
            likes=model_data.get("likes", 0),
        )

        gguf = model_data.get("gguf")
        if gguf:
            model.architecture = gguf.get("architecture", "")
            model.context_length = gguf.get("context_length", 0)

        try:
            model.files = await fetch_all_gguf_files_async(session, model.id)

            # Find smallest and largest that fit
            for f in model.files:
                if f.size <= max_size_bytes:
                    if model.smallest_fit is None:
                        model.smallest_fit = f
                    model.largest_fit = f
        except Exception as e:
            model.error = str(e)

        return model


def process_model_sync(model_data: dict, max_size_bytes: int) -> Model:
    """Process a single model (synchronous fallback)."""
    model = Model(
        id=model_data.get("id", ""),
        author=model_data.get("author", ""),
        downloads=model_data.get("downloads", 0),
        likes=model_data.get("likes", 0),
    )

    gguf = model_data.get("gguf")
    if gguf:
        model.architecture = gguf.get("architecture", "")
        model.context_length = gguf.get("context_length", 0)

    try:
        model.files = fetch_all_gguf_files_sync(model.id)
        for f in model.files:
            if f.size <= max_size_bytes:
                if model.smallest_fit is None:
                    model.smallest_fit = f
                model.largest_fit = f
    except Exception as e:
        model.error = str(e)

    return model


async def fetch_all_models_async(model_list: list[dict], max_size_bytes: int) -> list[Model]:
    """Fetch file sizes for all models concurrently."""
    semaphore = asyncio.Semaphore(MAX_CONCURRENT)

    async with aiohttp.ClientSession() as session:
        tasks = [process_model_async(session, m, max_size_bytes, semaphore) for m in model_list]
        return await asyncio.gather(*tasks)


def display_model_list(models: list[Model], max_size_gb: int, max_size_bytes: int):
    """Display the model list with sizes."""
    print(f"\n{BOLD}{CYAN}Trending GGUF Models (max {max_size_gb}GB){RESET}")
    print(f"{BOLD}{'━' * 95}{RESET}\n")

    header = f"{BOLD}{'MODEL':<45} {'DOWNLOADS':>10} {'LIKES':>6} {'SMALLEST':>12} {'LARGEST':>12} FIT{RESET}"
    print(header)
    print("─" * 95)

    for m in models:
        display_id = m.id[:42] + "..." if len(m.id) > 45 else m.id

        smallest = "?"
        largest = "?"
        fit = f"{YELLOW}?{RESET}"

        if m.error is None and m.files:
            if m.smallest_fit:
                smallest = format_size(m.smallest_fit.size)
                largest = format_size(m.largest_fit.size)
                fit = f"{GREEN}✓{RESET}"
            else:
                smallest = format_size(m.files[0].size)
                largest = format_size(m.files[-1].size)
                fit = f"{RED}✗{RESET}"

        print(f"{display_id:<45} {format_downloads(m.downloads):>10} {m.likes:>6} {smallest:>12} {largest:>12} {fit}")

    print(f"\nFound {BOLD}{len(models)}{RESET} models. Use {CYAN}--details MODEL_ID{RESET} for full file list.")


def show_model_details(model_id: str, max_size_bytes: int):
    """Show detailed info for a specific model."""
    print(f"\n{BOLD}{CYAN}Fetching details for: {model_id}{RESET}\n")

    # Fetch model info
    try:
        model_data = fetch_json_sync(f"{HF_API_BASE}/{model_id}")
    except Exception as e:
        print(f"{RED}Error: {e}{RESET}")
        return

    print(f"{BOLD}Model:{RESET}     {model_id}")
    print(f"{BOLD}Author:{RESET}    {model_data.get('author', 'unknown')}")
    print(f"{BOLD}Downloads:{RESET} {format_downloads(model_data.get('downloads', 0))}")
    print(f"{BOLD}Likes:{RESET}     {model_data.get('likes', 0)}")

    gguf = model_data.get("gguf")
    if gguf:
        if gguf.get("architecture"):
            print(f"{BOLD}Arch:{RESET}      {gguf['architecture']}")
        if gguf.get("context_length"):
            print(f"{BOLD}Context:{RESET}   {gguf['context_length']} tokens")

    # Fetch files
    files = fetch_all_gguf_files_sync(model_id)

    print(f"\n{BOLD}{YELLOW}Available GGUF Files:{RESET}")
    print("─" * 75)
    print(f"{BOLD}{'FILENAME':<50} {'SIZE':>12} FIT{RESET}")
    print("─" * 75)

    for f in files:
        display_name = f.name[:47] + "..." if len(f.name) > 50 else f.name
        fit = f"{GREEN}✓{RESET}" if f.size <= max_size_bytes else f"{RED}✗{RESET}"

        quality = ""
        for q, desc in QUANT_QUALITY.items():
            if q in f.name:
                quality = f" ({desc})"
                break

        print(f"{display_name:<50} {format_size(f.size):>12} {fit}{quality}")

    print(f"\n{CYAN}Download URL pattern:{RESET}")
    print(f"  https://huggingface.co/{model_id}/resolve/main/FILENAME")


async def main_async(args):
    """Main function using async."""
    max_size_bytes = args.max_size * 1024 ** 3

    if args.details:
        show_model_details(args.details, max_size_bytes)
        return

    async with aiohttp.ClientSession() as session:
        print(f"{CYAN}Fetching models...{RESET}", end="", flush=True)
        model_list = await fetch_models_async(session, args.sort, args.limit, args.search, args.author)
        print(f"\r{CYAN}Fetching file sizes for {len(model_list)} models...{RESET}", end="", flush=True)

    models = await fetch_all_models_async(model_list, max_size_bytes)
    print("\r" + " " * 50 + "\r", end="")  # Clear status line

    display_model_list(models, args.max_size, max_size_bytes)


def main_sync(args):
    """Main function using synchronous requests (fallback)."""
    max_size_bytes = args.max_size * 1024 ** 3

    if args.details:
        show_model_details(args.details, max_size_bytes)
        return

    print(f"{CYAN}Fetching models...{RESET}", end="", flush=True)
    model_list = fetch_models_sync(args.sort, args.limit, args.search, args.author)
    print(f"\r{CYAN}Fetching file sizes for {len(model_list)} models (sync mode, slower)...{RESET}")

    models = []
    for i, m in enumerate(model_list):
        print(f"\r  Processing {i+1}/{len(model_list)}: {m.get('id', '')[:50]:<50}", end="", flush=True)
        models.append(process_model_sync(m, max_size_bytes))
    print("\r" + " " * 80 + "\r", end="")

    display_model_list(models, args.max_size, max_size_bytes)


def main():
    parser = argparse.ArgumentParser(description="Discover GGUF models on HuggingFace")
    parser.add_argument("--max-size", type=int, default=DEFAULT_MAX_SIZE_GB, help=f"Maximum model size in GB (default: {DEFAULT_MAX_SIZE_GB})")
    parser.add_argument("--limit", type=int, default=DEFAULT_LIMIT, help=f"Number of models to fetch (default: {DEFAULT_LIMIT})")
    parser.add_argument("--sort", default=DEFAULT_SORT, help=f"Sort by: likes7d, downloads, likes (default: {DEFAULT_SORT})")
    parser.add_argument("--search", default="", help="Search for models by name")
    parser.add_argument("--author", default="", help="Filter by author")
    parser.add_argument("--details", default="", help="Show detailed info for a specific model")

    args = parser.parse_args()

    if HAS_AIOHTTP:
        asyncio.run(main_async(args))
    else:
        print(f"{YELLOW}Note: Install aiohttp for faster concurrent fetching: pip install aiohttp{RESET}\n")
        main_sync(args)


if __name__ == "__main__":
    main()
