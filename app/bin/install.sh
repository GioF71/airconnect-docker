#!/bin/bash

# errors
# 1 missing binary file

mkdir /app/release -p
mkdir /app/bin -p

ARCH=`uname -m`
echo "ARCH=[$ARCH]"

arch_amd64=x86_64
arch_arm_v7=armv7l
arch_arm_v8=aarch64

declare -A upnp_bin_file_name
upnp_bin_file_name[$arch_amd64]="airupnp-linux-x86_64"
upnp_bin_file_name[$arch_arm_v7]="airupnp-linux-arm"
upnp_bin_file_name[$arch_arm_v8]="airupnp-linux-aarch64"

UPNP_SELECT_BIN_FILE=${upnp_bin_file_name["${ARCH}"]}

if [ ! -f "/app/release/$UPNP_SELECT_BIN_FILE" ]; then
    echo "File /app/release/$UPNP_SELECT_BIN_FILE not found"
    exit 1
fi

if [ ! -f "/app/release/$UPNP_SELECT_BIN_FILE-static" ]; then
    echo "File /app/release/$UPNP_SELECT_BIN_FILE-static not found"
    exit 1
fi

echo "UPNP_SELECT_BIN_FILE=[$UPNP_SELECT_BIN_FILE]"

mv "/app/release/$UPNP_SELECT_BIN_FILE" /app/bin/airupnp-linux
chmod 755 /app/bin/airupnp-linux

mv "/app/release/$UPNP_SELECT_BIN_FILE-static" /app/bin/airupnp-linux-static
chmod 755 /app/bin/airupnp-linux-static

declare -A cast_bin_file_name
cast_bin_file_name[$arch_amd64]="aircast-linux-x86_64"
cast_bin_file_name[$arch_arm_v7]="aircast-linux-arm"
cast_bin_file_name[$arch_arm_v8]="aircast-linux-aarch64"

CAST_SELECT_BIN_FILE=${cast_bin_file_name["${ARCH}"]}

if [ ! -f "/app/release/$CAST_SELECT_BIN_FILE" ]; then
    echo "File /app/release/$CAST_SELECT_BIN_FILE not found"
    exit 1
fi

if [ ! -f "/app/release/$CAST_SELECT_BIN_FILE-static" ]; then
    echo "File /app/release/$CAST_SELECT_BIN_FILE-static not found"
    exit 1
fi

echo "CAST_SELECT_BIN_FILE=[$CAST_SELECT_BIN_FILE]"

mv "/app/release/$CAST_SELECT_BIN_FILE" /app/bin/aircast-linux
chmod 755 /app/bin/aircast-linux

mv "/app/release/$CAST_SELECT_BIN_FILE-static" /app/bin/aircast-linux-static
chmod 755 /app/bin/aircast-linux-static

mkdir /app/conf -p
echo "$AIR_CONNECT_VERSION" > /app/bin/version.txt

