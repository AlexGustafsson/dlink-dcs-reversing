#!/usr/bin/env bash

USE_DOCKER="${USE_DOCKER:-1}"

# The input firmware zip file as downloaded from D-Link's website
firmware_zip="$1"

# Output directory
output="$2"

# The RSA private key dumped from the device using the following command:
# pibinfo PriKey
private_key="$(cat << EOF
-----BEGIN RSA PRIVATE KEY-----
MIICXQIBAAKBgQC87QYtji6c0odxDs5SON+lpP0WE52WMK4OuRo8mHL0HWi0bZe0
dyDcJ6IO6EwKuIn0sJi5oY8/P0g3PAp4TTlZm6WBiwZ8XaPwnGY8Kd2lrcRvPR+0
UJ07hQ4RvhfFmanN8KEhe/myKkMldO/reyW8nwRRJwc2OHEvZ81KfAppWwIDAQAB
AoGAKGeIqrV9woxD6yn/dhYzvnlKpy4KxdQjZYKw2cTA0PR5MB1AFJhlrq/LOOT1
XlWZK3uZLhofSKeAClAM7S2W1fTbxmM8y/3g6c5Z3LbpNsvwVTWNp5ErbKMMeR+q
CnUA+NQ47f65EwUUyTIWhMcgINLjZT33Eg0DOPUVIoiDEgECQQDta5ehRLQQN8Tr
5OROwFrJA3qL4g+qmcnUrVfgDE/ro1zxcYluleg8ZCAJbhBgju7Y75voRlrZITkF
2dGFZq4PAkEAy7Xowx+az4ZU6Iw/AGmbv801digR9345UKZZNRLffLh0Hda2mPM+
25whWWTMiPcY0ty9/MZovZvVyuYuxzHb9QJBAJlbEgpdMmH3Y/9rTf2ASiPlV1bb
onrz82aowUY7LbRrRTG/wKHpuqSnl/n/WhzEtorx2qbiKvRtfUPGOowMkwkCQGgi
n9BPcbYwd2tBdlthoUrVPkUeisC399iwkN2+vhxltoYiYsmhXzqof6vRCXXiyv/P
9Bcp3hU/enT0YmlVpZkCQQDmsui42t0uup3hj6ITZa2JRkCCUI7qyU0HrE65lj88
s4IoUXr0RWUtnEbeDUbw2GtQVHNoldXVXSh30SDb6El7
-----END RSA PRIVATE KEY-----
EOF
)"

# Temporary directory used throughtout the unpacking
temp_directory="$(mktemp -d)"

# First unzip the file which contains a single tar file
unzip -p "$firmware_zip" > "$temp_directory/firmware.tar"

# Untar the file
tar --extract --directory="$temp_directory" --file="$temp_directory/firmware.tar"
rm "$temp_directory/firmware.tar"

# Decrypt the AES encryption key
echo "$private_key" > "$temp_directory/rsa.key"
openssl rsautl -decrypt -in "$temp_directory/aes.key.rsa" -out "$temp_directory/aes.key" -inkey "$temp_directory/rsa.key"

# Decrypt the update itself
openssl aes-128-cbc -v -nosalt -md md5 -d -in "$temp_directory/update.aes" -out "$temp_directory/update" -kfile "$temp_directory/aes.key"
openssl aes-128-cbc -v -nosalt -md md5 -d -in "$temp_directory/update.bin.aes" -out "$temp_directory/update.bin" -kfile "$temp_directory/aes.key"

# Move the firmware to the target directory
mkdir -p "$output/extracted"
mv "$temp_directory/update" "$output/extracted"
mv "$temp_directory/update.bin" "$output/extracted"

# Remove the temporary directory
rm -r "$temp_directory"

# Unpack the base64 encoded binary within update.bin
mkdir -p "$output/carved"
cat "$output/extracted/update.bin" | tr -d '\n' | sed 's!.*=== ddPack Boundary ===begin-base64 755 /dev/stdout!!' | rev | cut -c 5- | rev | base64 -d > "$output/carved/payload"

# Extract files from the update payload
if [[ "$USE_DOCKER" -eq 1 ]]; then
  docker run --rm -it -v "$(realpath "$output"):/output" binwalk --extract --directory "/output/carved" "/output/extracted/update"
else
  binwalk --extract --directory "$output/carved" "$output/extracted/update"
fi
