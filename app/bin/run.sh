#!/bin/bash

# errors
# 1 invalid parameter
# 2 invalid vorbis bitrate

DEFAULT_UID=1000
DEFAULT_GID=1000

if [ -z "${PUID}" ]; then
  PUID=$DEFAULT_UID;
  echo "Setting default value for PUID: ["$PUID"]"
fi

if [ -z "${PGID}" ]; then
  PGID=$DEFAULT_GID;
  echo "Setting default value for PGID: ["$PGID"]"
fi

DEFAULT_USER_NAME=airc
DEFAULT_GROUP_NAME=airc
DEFAULT_HOME_DIR=/home/$DEFAULT_USER_NAME

USER_NAME=$DEFAULT_USER_NAME
GROUP_NAME=$DEFAULT_GROUP_NAME
HOME_DIR=$DEFAULT_HOME_DIR

echo "Ensuring user with uid:[$PUID] gid:[$PGID] exists ...";
### create group if it does not exist
if [ ! $(getent group $PGID) ]; then
    echo "Group with gid [$PGID] does not exist, creating..."
    groupadd -g $PGID $GROUP_NAME
    echo "Group [$GROUP_NAME] with gid [$PGID] created."
else
    GROUP_NAME=$(getent group $PGID | cut -d: -f1)
    echo "Group with gid [$PGID] name [$GROUP_NAME] already exists."
fi
### create user if it does not exist
if [ ! $(getent passwd $PUID) ]; then
    echo "User with uid [$PUID] does not exist, creating..."
    useradd -g $PGID -u $PUID -M $USER_NAME
    echo "User [$USER_NAME] with uid [$PUID] created."
else
    USER_NAME=$(getent passwd $PUID | cut -d: -f1)
    echo "user with uid [$PUID] name [$USER_NAME] already exists."
    HOME_DIR="/home/$USER_NAME"
fi
### create home directory
if [ ! -d "$HOME_DIR" ]; then
    echo "Home directory [$HOME_DIR] not found, creating."
    mkdir -p $HOME_DIR
    echo ". done."
fi
chown -R $PUID:$PGID $HOME_DIR
chown -R $PUID:$PGID /config

if [[ -z "${AIRCONNECT_MODE}" ]]; then
    AIRCONNECT_MODE=upnp
fi

if [[ "${AIRCONNECT_MODE^^}" == "UPNP" ]]; then
    AIRCONNECT_MODE=upnp
    binary_file=/app/bin/airupnp-linux
elif [[ "${AIRCONNECT_MODE^^}" == "CAST" ]]; then
    AIRCONNECT_MODE=cast
    binary_file=/app/bin/aircast-linux
else
    echo "Invalid AIRCONNECT_MODE [${AIRCONNECT_MODE}], must be either ""upnp"" or ""cast"""
    exit 1
fi

if [[ -n "$PREFER_STATIC" ]]; then
    echo "PREFER_STATIC=[$PREFER_STATIC]"
    if [[ "${PREFER_STATIC^^}" == "YES" || "${PREFER_STATIC^^}" == "Y" ]]; then
        echo "Selecting static version ..."
        binary_file=$binary_file-static
        echo ". done."
    elif [[ "${PREFER_STATIC^^}" != "NO" && "${PREFER_STATIC^^}" != "N" ]]; then
        echo "Invalid value for PREFER_STATIC [$PREFER_STATIC]!"
        exit 2
    fi
fi

version=$(cat /app/bin/version.txt)

echo "Using AirConnect [${AIRCONNECT_MODE}] version [${version}]"

CONFIG_FILE_NAME="config.xml"
if [[ -n "${CONFIG_FILE_PREFIX}" ]]; then
    CONFIG_FILE_NAME="${CONFIG_FILE_PREFIX}-config.xml"
fi

if [ ! -f /config/$CONFIG_FILE_NAME ]; then
    echo "Configuration file not found, creating reference configuration file ..."
    CREATE_CFG_FILE="$binary_file -i /config/$CONFIG_FILE_NAME"    
    echo "Command Line (config file creation): ["$CREATE_CFG_FILE"]"
    su - $USER_NAME -c "$CREATE_CFG_FILE"
    echo "Configuration file created."
else
    echo "Configuration file [/config/$CONFIG_FILE_NAME] already exists"
fi

CMD_LINE="$binary_file -x /config/$CONFIG_FILE_NAME -Z"

if [[ -n "${CODEC}" ]]; then
    CMD_LINE="$CMD_LINE -c ${CODEC}"
fi

echo "Command Line: ["$CMD_LINE"]"
su - $USER_NAME -c "$CMD_LINE"
