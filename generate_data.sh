#!/usr/bin/env bash
# Generates 4 folders, each with 40 sample records: username, date, %, age, hash
set -euo pipefail

DATASETS_DIR="$(dirname "$0")/datasets"

USERNAMES=(
  alice bob charlie diana eve frank grace henry iris jack
  karen leo mia noah olivia peter quinn rose sam tina
  uma victor wendy xander yara zack amber blake caleb dana
  ethan fiona gary hailey ivan julia kevin laura mason nina
  oscar paula ryan sophia tyler ulysses violet wyatt ximena yusuf
  zara adam bella carter daisy elliot flora george holly ian
  jasmine kyle lily mike nina omar penny quincy rachel steven
  theresa ursula victor wanda xavier yasmine zoe andrew brianna cole
)

generate_hash() {
  echo -n "$1" | md5sum | awk '{print $1}'
}

random_date() {
  local year=$(( 2020 + RANDOM % 6 ))
  local month=$(printf "%02d" $(( 1 + RANDOM % 12 )))
  local day=$(printf "%02d" $(( 1 + RANDOM % 28 )))
  echo "${year}-${month}-${day}"
}

random_percent() {
  printf "%.2f" "$(echo "scale=2; $RANDOM % 10000 / 100" | bc)"
}

random_age() {
  echo $(( 18 + RANDOM % 48 ))
}

mkdir -p "$DATASETS_DIR"

for folder_num in 1 2 3 4; do
  folder="$DATASETS_DIR/folder${folder_num}"
  mkdir -p "$folder"
  outfile="$folder/data.csv"

  echo "username,date,percentage,age,hash" > "$outfile"

  for i in $(seq 1 40); do
    # Pick username: offset by folder so folders have different data
    idx=$(( (folder_num - 1) * 10 + (i - 1) % ${#USERNAMES[@]} ))
    idx=$(( idx % ${#USERNAMES[@]} ))
    base_user="${USERNAMES[$idx]}"
    username="${base_user}${folder_num}${i}"

    date=$(random_date)
    pct=$(random_percent)
    age=$(random_age)
    hash=$(generate_hash "$username")

    echo "${username},${date},${pct},${age},${hash}" >> "$outfile"
  done

  echo "Created $outfile (40 records)"
done

echo "Done. Dataset folders are in: $DATASETS_DIR"
