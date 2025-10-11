#!/bin/bash

TODAY=$(date '+%Y-%m-%d')

echo "TODAY=${TODAY}"

docker buildx build . \
    --progress=plain \
    --platform linux/amd64,linux/arm64/v8,linux/arm/v7,linux/arm/v5 \
    --tag giof71/airconnect:latest \
    --tag giof71/airconnect:stable \
    --tag giof71/airconnect:debian \
    --tag giof71/airconnect:debian-${TODAY} \
    --push
