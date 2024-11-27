#!/bin/bash

DIR=$(pwd)
METADATA_URL="https://updater.refx.online/metadata.json"
TEMP_DIR="$DIR/temp"
METADATA_FILE="$TEMP_DIR/metadata.json"

mkdir -p "$TEMP_DIR"

command -v curl >/dev/null 2>&1 || { echo "curl is required but not installed."; exit 1; }
command -v md5sum >/dev/null 2>&1 || { echo "md5sum is required but not installed."; exit 1; }
command -v jq >/dev/null 2>&1 || { echo "jq is required but not installed."; exit 1; }

echo "fetching metadata."
curl -s "$METADATA_URL" -o "$METADATA_FILE"

if [ $? -ne 0 ] || [ ! -f "$METADATA_FILE" ]; then
    echo "failed to fetch metadata."
    exit 1
fi

jq -c '.[]' "$METADATA_FILE" | while read -r file_data; do
    FILENAME=$(echo "$file_data" | jq -r '.filename')
    FILE_HASHMD5=$(echo "$file_data" | jq -r '.file_hashmd5')
    FILE_URL=$(echo "$file_data" | jq -r '.url_full')
    FILE_PATH="$DIR/$FILENAME"

    echo -ne "$FILENAME\r"

    if [ -f "$FILE_PATH" ]; then
        LOCAL_HASHMD5=$(md5sum "$FILE_PATH" | awk '{print $1}')
        if [ "$LOCAL_HASHMD5" == "$FILE_HASHMD5" ]; then
            echo -e "$FILENAME - \e[32mup to date.\e[0m"
            continue
        else
            echo -e "$FILENAME - \e[33mhash mismatch, updating.\e[0m"
        fi
    else
        echo -e "$FILENAME - \e[33mnot found, downloading.\e[0m"
    fi

    echo -ne "downloading file: $FILENAME\r"
    curl -sL "$FILE_URL" -o "$FILE_PATH"

    if [ $? -ne 0 ]; then
        echo -e "downloading file: $FILENAME - \e[31mfailed\e[0m"
        continue
    fi

    echo -e "downloading file: $FILENAME - \e[32msuccess\e[0m"
done

rm -rf "$TEMP_DIR"
echo -e "\nwelcome aboard."
