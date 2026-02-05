#!/usr/bin/env bash

set -euo pipefail

MAX_AGE_DAYS=40
TARGET_DIR="."

PATTERNS=(
    '*.log.[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]'
    '*.[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]'
    '*.gz.[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]'
)

today=$(date +%s)

echo "=== Archiving and cleaning old logs ==="
echo "Today:          $(date -d "@$today" '+%Y-%m-%d')"
echo "Delete files older than: $MAX_AGE_DAYS days"
echo ""

declare -i count_archived=0
declare -i count_deleted=0

for pattern in "${PATTERNS[@]}"; do
    while IFS= read -r -d '' file; do
        date_str=""
        if [[ $file =~ ([0-9]{4}-[0-9]{2}-[0-9]{2})(\.|$) ]]; then
            date_str="${BASH_REMATCH[1]}"
        else
            echo "  Skipping (no legible date): $file"
            continue
        fi

        file_date=$(date -d "$date_str" +%s 2>/dev/null || echo "invalid")
        if [[ "$file_date" == "invalid" ]]; then
            echo "  Skipping (invalid date): $file"
            continue
        fi

        age_days=$(( (today - file_date) / 86400 ))

        if (( age_days > MAX_AGE_DAYS )); then
            echo "  DELETE (too old: ${age_days} days) → $file"
            rm -f -- "$file"
            ((count_deleted++))
        elif [[ -f "${file}.tar.gz" ]]; then
            :
        else
            echo "  Archiving (${age_days} days) → $file"
            tar -czf "${file}.tar.gz" -- "$file" >/dev/null
            if [[ $? -eq 0 ]]; then
                rm -f -- "$file"
                ((count_archived++))
            else
                echo "  Error creating archive: ${file}.tar.gz"
            fi
        fi

    done < <(find "$TARGET_DIR" -maxdepth 1 -type f -name "$pattern" -print0 2>/dev/null)
done

echo ""
echo "Summary:"
echo "  New files archived: $count_archived"
echo "  Old files deleted:  $count_deleted"
echo "Done."
