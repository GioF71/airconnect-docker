#!/bin/bash

mkdir -p /app/release
cd /app/release
wget "https://github.com/philippe44/AirConnect/releases/download/${AIR_CONNECT_VERSION}/AirConnect-${AIR_CONNECT_VERSION}.zip"
unzip AirConnect*zip
rm AirConnect*zip

