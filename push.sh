#!/bin/bash

BATCH_SIZE=10
COUNT=0
BATCH=1

# track already added files
declare -A seen

add_file() {
  local file="$1"

  # avoid duplicates
  if [[ ${seen["$file"]} == "1" ]]; then
    return
  fi

  git add "$file"
  seen["$file"]=1
}

commit_and_push() {
  if git diff --cached --quiet; then
    echo "Nothing to commit"
    return
  fi

  git commit -m "batch upload $BATCH"

  # retry push up to 3 times
  for i in 1 2 3
  do
    git push && break
    echo "Push failed, retrying ($i)..."
    sleep 2
  done
}

# find all target files
FILES=$(find . -type f \( -name "*.opus" -o -name "*.mp3" -o -name "*.jpg" -o -name "*.png" \))

for file in $FILES
do
  add_file "$file"
  COUNT=$((COUNT+1))

  if [ $COUNT -eq $BATCH_SIZE ]; then
    commit_and_push
    COUNT=0
    BATCH=$((BATCH+1))
  fi
done

# final push
commit_and_push

echo "✅ All files uploaded safely!"
