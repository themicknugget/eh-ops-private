#!/usr/bin/env bash
#
# hf-model-scout.sh - Discover GGUF models on HuggingFace that fit your hardware
#
# Usage:
#   ./hf-model-scout.sh                    # Show trending models that fit 120GB
#   ./hf-model-scout.sh --max-size 80      # Custom max size in GB
#   ./hf-model-scout.sh --sort downloads   # Sort by downloads instead of trending
#   ./hf-model-scout.sh --search "qwen"    # Search for specific models
#   ./hf-model-scout.sh --author bartowski  # Filter by author
#   ./hf-model-scout.sh --details MODEL_ID # Show detailed info for a model

set -euo pipefail

# =============================================================================
# Configuration - Strix Halo defaults
# =============================================================================
DEFAULT_MAX_SIZE_GB=120         # 128GB UMA - 8GB system
DEFAULT_LIMIT=30
DEFAULT_SORT="likes7d"          # Trending (likes in last 7 days)
HF_API_BASE="https://huggingface.co/api/models"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color
BOLD='\033[1m'

# =============================================================================
# Hardware profiles
# =============================================================================
declare -A HARDWARE_PROFILES=(
    ["strix-halo"]="120"     # 128GB UMA - 8GB system
)

# =============================================================================
# Quantization info
# =============================================================================
declare -A QUANT_QUALITY=(
    ["Q8_0"]="Excellent - Near lossless"
    ["Q6_K"]="Very Good - Reasoning/math"
    ["Q5_K_M"]="Good - Recommended balance"
    ["Q5_K_S"]="Good - Slightly smaller"
    ["Q4_K_M"]="Decent - Most popular"
    ["Q4_K_S"]="Decent - Smaller"
    ["Q3_K_M"]="Fair - Quality loss"
    ["Q3_K_L"]="Fair - Larger Q3"
    ["Q2_K"]="Poor - Extreme compression"
    ["IQ4_XS"]="Good - imatrix optimized"
    ["IQ3_M"]="Fair - imatrix optimized"
)

# =============================================================================
# Helper functions
# =============================================================================
usage() {
    cat << EOF
${BOLD}hf-model-scout.sh${NC} - Discover GGUF models for your hardware

${BOLD}USAGE:${NC}
    $(basename "$0") [OPTIONS]

${BOLD}OPTIONS:${NC}
    -m, --max-size SIZE     Maximum model size in GB (default: $DEFAULT_MAX_SIZE_GB)
    -l, --limit N           Number of models to fetch (default: $DEFAULT_LIMIT)
    -s, --sort FIELD        Sort by: likes7d (trending), downloads, likes (default: $DEFAULT_SORT)
    -q, --search QUERY      Search for models by name
    -a, --author AUTHOR     Filter by author (e.g., bartowski, unsloth, TheBloke)
    -p, --profile PROFILE   Use hardware profile: ${!HARDWARE_PROFILES[*]}
    -d, --details MODEL_ID  Show detailed info for a specific model
    -f, --files MODEL_ID    List all GGUF files for a model
    --json                  Output raw JSON
    -h, --help              Show this help

${BOLD}EXAMPLES:${NC}
    # Show trending GGUF models that fit Strix Halo (120GB)
    $(basename "$0")

    # Search for Qwen models
    $(basename "$0") --search qwen

    # Show bartowski's most downloaded models
    $(basename "$0") --author bartowski --sort downloads

    # Get details about a specific model
    $(basename "$0") --details bartowski/Llama-3.3-70B-Instruct-GGUF

    # List all GGUF files for a model
    $(basename "$0") --files bartowski/Llama-3.3-70B-Instruct-GGUF

${BOLD}HARDWARE PROFILES:${NC}
EOF
    for profile in "${!HARDWARE_PROFILES[@]}"; do
        printf "    %-20s %s GB\n" "$profile" "${HARDWARE_PROFILES[$profile]}"
    done
    echo ""
}

bytes_to_gb() {
    local bytes=$1
    awk "BEGIN {printf \"%.2f\", $bytes / 1073741824}"
}

format_size() {
    local gb=$1
    # Handle non-numeric input
    if [[ "$gb" == "?" ]] || [[ -z "$gb" ]]; then
        echo "?"
        return
    fi
    if awk "BEGIN {exit !($gb < 1)}"; then
        awk "BEGIN {printf \"%.0f MB\", $gb * 1024}"
    else
        printf "%.1f GB" "$gb"
    fi
}

format_downloads() {
    local num=$1
    if (( num >= 1000000 )); then
        awk "BEGIN {printf \"%.1fM\", $num / 1000000}"
    elif (( num >= 1000 )); then
        awk "BEGIN {printf \"%.1fK\", $num / 1000}"
    else
        echo "$num"
    fi
}

check_dependencies() {
    local missing=()
    for cmd in curl jq awk; do
        if ! command -v "$cmd" &> /dev/null; then
            missing+=("$cmd")
        fi
    done
    if [[ ${#missing[@]} -gt 0 ]]; then
        echo -e "${RED}Error: Missing required commands: ${missing[*]}${NC}" >&2
        exit 1
    fi
}

# =============================================================================
# API functions
# =============================================================================
fetch_models() {
    local sort="$1"
    local limit="$2"
    local search="${3:-}"
    local author="${4:-}"

    local url="${HF_API_BASE}?filter=gguf&pipeline_tag=text-generation&sort=${sort}&direction=-1&limit=${limit}"

    [[ -n "$search" ]] && url+="&search=${search}"
    [[ -n "$author" ]] && url+="&author=${author}"

    curl -s "$url"
}

fetch_model_details() {
    local model_id="$1"
    curl -s "${HF_API_BASE}/${model_id}"
}

fetch_model_tree() {
    local model_id="$1"
    local path="${2:-}"
    if [[ -n "$path" ]]; then
        curl -s "${HF_API_BASE}/${model_id}/tree/main/${path}"
    else
        curl -s "${HF_API_BASE}/${model_id}/tree/main"
    fi
}

# Get all GGUF files including split files in subdirectories
# Output: filename\tsize (one per line, sorted by size)
get_all_gguf_files() {
    local model_id="$1"
    local tree
    tree=$(fetch_model_tree "$model_id")

    # Temp file for collecting results
    local tmpfile
    tmpfile=$(mktemp)
    trap "rm -f $tmpfile" RETURN

    # Get root-level .gguf files
    echo "$tree" | jq -r '
        .[] | select(.type == "file" and (.path | endswith(".gguf")))
        | "\(.path)\t\(.size // 0)"
    ' >> "$tmpfile"

    # Get directories that might contain split .gguf files
    local dirs
    dirs=$(echo "$tree" | jq -r '.[] | select(.type == "directory") | .path')

    # Check each directory for .gguf files and sum their sizes
    while IFS= read -r dir; do
        [[ -z "$dir" ]] && continue

        local subdir_tree
        subdir_tree=$(fetch_model_tree "$model_id" "$dir")

        # Check if directory contains .gguf files
        local has_gguf
        has_gguf=$(echo "$subdir_tree" | jq '[.[] | select(.path | endswith(".gguf"))] | length')

        if [[ "$has_gguf" -gt 0 ]]; then
            # Sum all .gguf file sizes in this directory
            local total_size
            total_size=$(echo "$subdir_tree" | jq '[.[] | select(.path | endswith(".gguf")) | .size // 0] | add // 0')

            # Use directory name as the "filename" (extract quant name)
            local display_name
            display_name=$(basename "$dir").gguf

            echo -e "${display_name}\t${total_size}" >> "$tmpfile"
        fi
    done <<< "$dirs"

    # Sort by size and output
    sort -t$'\t' -k2 -n "$tmpfile"
}

# =============================================================================
# Display functions
# =============================================================================
show_model_list() {
    local models="$1"
    local max_size_gb="$2"
    local max_size_bytes
    max_size_bytes=$(awk "BEGIN {printf \"%.0f\", $max_size_gb * 1073741824}")

    echo -e "\n${BOLD}${CYAN}Trending GGUF Models (max ${max_size_gb}GB)${NC}"
    echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"

    printf "${BOLD}%-50s %10s %8s %10s${NC}\n" "MODEL" "DOWNLOADS" "LIKES" "SIZE"
    echo "────────────────────────────────────────────────────────────────────────────────"

    local count=0
    while IFS=$'\t' read -r id downloads likes gguf_total; do
        [[ -z "$id" ]] && continue

        local size_gb="?"
        local fits="${GREEN}✓${NC}"

        if [[ "$gguf_total" != "null" ]] && [[ -n "$gguf_total" ]] && [[ "$gguf_total" != "0" ]]; then
            size_gb=$(bytes_to_gb "$gguf_total")
            if awk "BEGIN {exit !($gguf_total > $max_size_bytes)}"; then
                fits="${RED}✗${NC}"
            fi
        fi

        # Truncate long model names
        local display_id="$id"
        if [[ ${#id} -gt 48 ]]; then
            display_id="${id:0:45}..."
        fi

        printf "%-50s %10s %8s %8s %b\n" \
            "$display_id" \
            "$(format_downloads "$downloads")" \
            "$likes" \
            "$(format_size "$size_gb")" \
            "$fits"

        ((count++)) || true
    done < <(echo "$models" | jq -r '.[] | "\(.id)\t\(.downloads // 0)\t\(.likes // 0)\t\(.gguf.total // 0)"')

    echo ""
    echo -e "Found ${BOLD}$count${NC} models. Use ${CYAN}--details MODEL_ID${NC} for more info."
    echo -e "${YELLOW}Note: Size shown is from API metadata (often unavailable). Use --details for accurate file sizes.${NC}"
}

show_model_details() {
    local model_id="$1"
    local max_size_gb="$2"

    echo -e "\n${BOLD}${CYAN}Fetching details for: $model_id${NC}\n"

    local details
    details=$(fetch_model_details "$model_id")

    if [[ $(echo "$details" | jq -r '.error // empty') != "" ]]; then
        echo -e "${RED}Error: Model not found${NC}"
        return 1
    fi

    # Basic info
    local downloads likes created author pipeline
    downloads=$(echo "$details" | jq -r '.downloads // 0')
    likes=$(echo "$details" | jq -r '.likes // 0')
    created=$(echo "$details" | jq -r '.createdAt // "unknown"' | cut -dT -f1)
    author=$(echo "$details" | jq -r '.author // "unknown"')
    pipeline=$(echo "$details" | jq -r '.pipeline_tag // "unknown"')

    echo -e "${BOLD}Model:${NC}     $model_id"
    echo -e "${BOLD}Author:${NC}    $author"
    echo -e "${BOLD}Task:${NC}      $pipeline"
    echo -e "${BOLD}Downloads:${NC} $(format_downloads "$downloads")"
    echo -e "${BOLD}Likes:${NC}     $likes"
    echo -e "${BOLD}Created:${NC}   $created"

    # GGUF metadata
    local arch ctx_len
    arch=$(echo "$details" | jq -r '.gguf.architecture // "unknown"')
    ctx_len=$(echo "$details" | jq -r '.gguf.context_length // "unknown"')

    if [[ "$arch" != "unknown" ]]; then
        echo -e "${BOLD}Architecture:${NC} $arch"
    fi
    if [[ "$ctx_len" != "unknown" ]]; then
        echo -e "${BOLD}Context:${NC}   $ctx_len tokens"
    fi

    # Tags
    local tags
    tags=$(echo "$details" | jq -r '.tags // [] | map(select(startswith("license:") or . == "gguf" or contains("B") or contains("instruct"))) | join(", ")')
    if [[ -n "$tags" ]]; then
        echo -e "${BOLD}Tags:${NC}      $tags"
    fi

    # GGUF files - use tree API for file sizes (including split files)
    echo -e "\n${BOLD}${YELLOW}Available GGUF Files:${NC}"
    echo "────────────────────────────────────────────────────────────────────────────────"
    printf "${BOLD}%-55s %10s %s${NC}\n" "FILENAME" "SIZE" "FIT"
    echo "────────────────────────────────────────────────────────────────────────────────"

    local max_size_bytes
    max_size_bytes=$(awk "BEGIN {printf \"%.0f\", $max_size_gb * 1073741824}")

    get_all_gguf_files "$model_id" | while IFS=$'\t' read -r filename size; do
        [[ -z "$filename" ]] && continue

        local size_gb="?"
        local fits="${YELLOW}?${NC}"
        local quant_info=""

        if [[ "$size" != "0" ]] && [[ -n "$size" ]]; then
            size_gb=$(bytes_to_gb "$size")
            if awk "BEGIN {exit !($size <= $max_size_bytes)}"; then
                fits="${GREEN}✓${NC}"
            else
                fits="${RED}✗${NC}"
            fi
        fi

        # Extract quantization from filename
        for quant in "${!QUANT_QUALITY[@]}"; do
            if [[ "$filename" == *"$quant"* ]]; then
                quant_info=" (${QUANT_QUALITY[$quant]})"
                break
            fi
        done

        # Truncate long filenames
        local display_name="$filename"
        if [[ ${#filename} -gt 53 ]]; then
            display_name="${filename:0:50}..."
        fi

        printf "%-55s %10s %b%s\n" "$display_name" "$(format_size "$size_gb")" "$fits" "$quant_info"
    done

    echo ""
    echo -e "${CYAN}Download URL pattern:${NC}"
    echo "  https://huggingface.co/${model_id}/resolve/main/FILENAME"
}

show_files_only() {
    local model_id="$1"
    local max_size_gb="$2"
    local max_size_bytes
    max_size_bytes=$(awk "BEGIN {printf \"%.0f\", $max_size_gb * 1073741824}")

    echo -e "\n${BOLD}GGUF files for: $model_id${NC}\n"

    get_all_gguf_files "$model_id" | while IFS=$'\t' read -r filename size; do
        [[ -z "$filename" ]] && continue

        local size_gb="0"
        local fits="?"

        if [[ "$size" != "0" ]] && [[ -n "$size" ]]; then
            size_gb=$(bytes_to_gb "$size")
            if awk "BEGIN {exit !($size <= $max_size_bytes)}"; then
                fits="YES"
            else
                fits="NO"
            fi
        fi

        printf "%s\t%.1fGB\t%s\n" "$filename" "$size_gb" "$fits"
    done
}

# =============================================================================
# Main
# =============================================================================
main() {
    check_dependencies

    local max_size_gb="$DEFAULT_MAX_SIZE_GB"
    local limit="$DEFAULT_LIMIT"
    local sort="$DEFAULT_SORT"
    local search=""
    local author=""
    local details_model=""
    local files_model=""
    local json_output=false

    while [[ $# -gt 0 ]]; do
        case "$1" in
            -m|--max-size)
                max_size_gb="$2"
                shift 2
                ;;
            -l|--limit)
                limit="$2"
                shift 2
                ;;
            -s|--sort)
                sort="$2"
                shift 2
                ;;
            -q|--search)
                search="$2"
                shift 2
                ;;
            -a|--author)
                author="$2"
                shift 2
                ;;
            -p|--profile)
                if [[ -v "HARDWARE_PROFILES[$2]" ]]; then
                    max_size_gb="${HARDWARE_PROFILES[$2]}"
                else
                    echo -e "${RED}Unknown profile: $2${NC}" >&2
                    echo "Available: ${!HARDWARE_PROFILES[*]}" >&2
                    exit 1
                fi
                shift 2
                ;;
            -d|--details)
                details_model="$2"
                shift 2
                ;;
            -f|--files)
                files_model="$2"
                shift 2
                ;;
            --json)
                json_output=true
                shift
                ;;
            -h|--help)
                usage
                exit 0
                ;;
            *)
                echo -e "${RED}Unknown option: $1${NC}" >&2
                usage
                exit 1
                ;;
        esac
    done

    # Show files only
    if [[ -n "$files_model" ]]; then
        show_files_only "$files_model" "$max_size_gb"
        exit 0
    fi

    # Show model details
    if [[ -n "$details_model" ]]; then
        show_model_details "$details_model" "$max_size_gb"
        exit 0
    fi

    # Fetch and display model list
    local models
    models=$(fetch_models "$sort" "$limit" "$search" "$author")

    if $json_output; then
        echo "$models"
    else
        show_model_list "$models" "$max_size_gb"
    fi
}

main "$@"
