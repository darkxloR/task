#!/usr/bin/env bash
# Picks 5 random records from datasets and inserts them into ClickHouse
set -euo pipefail

DATASETS_DIR="$(dirname "$0")/datasets"
CH_HOST="${CLICKHOUSE_HOST:-localhost}"
CH_PORT="${CLICKHOUSE_PORT:-8123}"
CH_USER="${CLICKHOUSE_USER:-root}"
CH_PASS="${CLICKHOUSE_PASSWORD:-123}"
CH_DB="${CLICKHOUSE_DB:-database}"
CH_TABLE="user_samples"
CH_URL="http://${CH_HOST}:${CH_PORT}"

# ── helpers ──────────────────────────────────────────────────────────────────

ch_query() {
  local query="$1"
  curl -sf \
    -X POST "${CH_URL}/?database=${CH_DB}" \
    -u "${CH_USER}:${CH_PASS}" \
    --data-binary "${query}"
}

ch_insert() {
  local data="$1"
  local query="INSERT INTO ${CH_DB}.${CH_TABLE} (username,sample_date,percentage,age,username_hash,folder) FORMAT CSV"
  curl -sf \
    -X POST "${CH_URL}/?query=$(python3 -c "import urllib.parse,sys; print(urllib.parse.quote(sys.argv[1]))" "${query}")" \
    -u "${CH_USER}:${CH_PASS}" \
    --data-binary "${data}"
}

# ── ensure table exists ───────────────────────────────────────────────────────

echo "[1/3] Ensuring table ${CH_DB}.${CH_TABLE} exists..."
ch_query "
CREATE TABLE IF NOT EXISTS ${CH_DB}.${CH_TABLE} (
    id          UUID    DEFAULT generateUUIDv4(),
    username    String,
    sample_date Date,
    percentage  Float64,
    age         UInt8,
    username_hash String,
    folder      String,
    inserted_at DateTime DEFAULT now()
) ENGINE = MergeTree()
ORDER BY (inserted_at, username)
"
echo "Table ready."

# ── collect all records from all folders ─────────────────────────────────────

echo "[2/3] Collecting records from datasets..."

TMP=$(mktemp)
trap 'rm -f "$TMP"' EXIT

for folder_num in 1 2 3 4; do
  csv="$DATASETS_DIR/folder${folder_num}/data.csv"
  if [[ ! -f "$csv" ]]; then
    echo "Warning: $csv not found — run generate_data.sh first" >&2
    continue
  fi
  # skip header line; prepend folder name as extra column
  tail -n +2 "$csv" | while IFS=',' read -r user date pct age hash; do
    echo "${user},${date},${pct},${age},${hash},folder${folder_num}"
  done >> "$TMP"
done

total=$(wc -l < "$TMP")
if [[ "$total" -lt 5 ]]; then
  echo "Error: need at least 5 records (found ${total}). Run generate_data.sh first." >&2
  exit 1
fi

# ── pick 5 random rows ────────────────────────────────────────────────────────

SELECTED=$(shuf -n 5 "$TMP")

echo ""
echo "Selected 5 records:"
printf "%-20s %-12s %-8s %-5s %-34s %s\n" "USERNAME" "DATE" "%" "AGE" "HASH" "FOLDER"
printf -- "%-20s %-12s %-8s %-5s %-34s %s\n" "--------------------" "------------" "--------" "-----" "----------------------------------" "--------"
echo "$SELECTED" | while IFS=',' read -r u d p a h f; do
  printf "%-20s %-12s %-8s %-5s %-34s %s\n" "$u" "$d" "$p" "$a" "$h" "$f"
done
echo ""

# ── insert into ClickHouse ────────────────────────────────────────────────────

echo "[3/3] Inserting into ${CH_DB}.${CH_TABLE}..."
ch_insert "$SELECTED"
echo "Insert complete."

echo ""
echo "Verify with:"
echo "  curl -sf 'http://${CH_HOST}:${CH_PORT}/' -u '${CH_USER}:${CH_PASS}' \\"
echo "    --data-urlencode \"query=SELECT * FROM ${CH_DB}.${CH_TABLE} ORDER BY inserted_at DESC LIMIT 10 FORMAT Pretty\""
