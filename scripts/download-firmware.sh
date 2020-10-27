#!/usr/bin/env bash

model="$1"
output_directory="$2"
firmware_index="$3"

function search() {
  query="$1"
  curl -s "https://eu.dlink.com/uk/en/search/suggestions?mode=ajax&q=$query" | grep -e 'item-listing.*href' | sed 's/.*href="\([^"]\+\)".*/\1/'
}

function find_firmware() {
  page="$1"
  curl -s "https://eu.dlink.com$page" | grep "href" | sed 's/.*href="\([^"]\+\)".*/\1/' | grep ".zip"
}

function find_all_firmware() {
  while read -r page; do
    find_firmware "$page"
  done
}

search_result="$(search "$model")"
if [[ -z "$search_result" ]]; then
  echo "Unable to find any matching model"
  exit 1
fi

all_firmware="$(echo "$search_result" | find_all_firmware)"
if [[ -z "$all_firmware" ]]; then
  echo "Unable to find any firmware for that model"
  exit 1
fi

if [[ -z "$firmware_index" ]]; then
  echo "Found firmware the following firmware"
  echo "$all_firmware" | nl -w1 -s' '
  echo -ne "\nWhich firmware do you want to download? "
  read firmware_index
fi

firmware="$(echo "$all_firmware" | sed -n "${firmware_index}p")"
if [[ -z "$firmware" ]]; then
  echo "No such firmware"
  exit 1
fi

wget --directory-prefix="$output_directory" "$firmware"
