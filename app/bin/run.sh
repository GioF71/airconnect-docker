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

DEFAULT_CONFIG_DIR=/config
FALLBACK_CONFIG_DIR=/tmp
CONFIG_DIR=$DEFAULT_CONFIG_DIR

DEFAULT_USER_NAME=airc
DEFAULT_GROUP_NAME=airc
DEFAULT_HOME_DIR=/home/$DEFAULT_USER_NAME

USER_NAME=$DEFAULT_USER_NAME
GROUP_NAME=$DEFAULT_GROUP_NAME
HOME_DIR=$DEFAULT_HOME_DIR

uid=$(id -u)
echo "Container is running with uid=[$uid]"
user_mode=1
echo "USER_MODE=[${USER_MODE}]"
if [[ $uid -eq 0 ]]; then
    if [[ -n "${USER_MODE}" ]]; then
        if [[ "${USER_MODE^^}" == "NO" ]] || [[ "${USER_MODE^^}" == "N" ]]; then
            user_mode=0
        elif [[ "${USER_MODE^^}" != "YES" ]] && [[ "${USER_MODE^^}" != "Y" ]]; then
            echo "Invalid USER_MODE=[${USER_MODE}]"
            exit 1
        fi
    fi
else
    user_mode=0
fi
echo "User mode enabled: [$user_mode]"

if [[ $user_mode -eq 1 ]]; then
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
fi

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

use_config_volume=1
if [[ -n "${USE_CONFIG_VOLUME}" ]]; then
    if [[ "${USE_CONFIG_VOLUME^^}" == "NO" ]] || [[ "${USE_CONFIG_VOLUME^^}" == "N" ]]; then
        use_config_volume=0
    elif [[ "${USE_CONFIG_VOLUME^^}" != "YES" ]] && [[ "${USE_CONFIG_VOLUME^^}" != "Y" ]]; then
        echo "Invalid USE_CONFIG_VOLUME=[${USE_CONFIG_VOLUME}]"
        exit 1
    fi
fi

if [ $use_config_volume -eq 1 ]; then
    if [ -w "$CONFIG_DIR" ]; then
        echo "Config directory [$CONFIG_DIR] is writable"
    else
        echo "Config directory [$CONFIG_DIR] is not writable, using $FALLBACK_CONFIG_DIR"
        CONFIG_DIR=$FALLBACK_CONFIG_DIR
    fi
else
    echo "USE_CONFIG_VOLUME=[${USE_CONFIG_VOLUME}], so we are using $FALLBACK_CONFIG_DIR"
    CONFIG_DIR=$FALLBACK_CONFIG_DIR
fi

if [ ! -f $CONFIG_DIR/$CONFIG_FILE_NAME ]; then
    echo "Configuration file not found, creating reference configuration file ..."
    CREATE_CFG_FILE="$binary_file -i $CONFIG_DIR/$CONFIG_FILE_NAME"    
    echo "Command Line (config file creation): ["$CREATE_CFG_FILE"]"
    su - $USER_NAME -c "$CREATE_CFG_FILE"
    echo "Configuration file created."
else
    echo "Configuration file [/config/$CONFIG_FILE_NAME] already exists"
fi

CMD_LINE="$binary_file -x $CONFIG_DIR/$CONFIG_FILE_NAME -Z"

if [[ -n "${LOG_LEVEL_ALL}" ]]; then
    CMD_LINE="$CMD_LINE -d all=${LOG_LEVEL_ALL}"
fi

if [[ -n "${LOG_LEVEL_MAIN}" ]]; then
    CMD_LINE="$CMD_LINE -d main=${LOG_LEVEL_MAIN}"
fi

if [[ -n "${LOG_LEVEL_RAOP}" ]]; then
    CMD_LINE="$CMD_LINE -d raop=${LOG_LEVEL_RAOP}"
fi

if [[ -n "${LOG_LEVEL_UTIL}" ]]; then
    CMD_LINE="$CMD_LINE -d util=${LOG_LEVEL_UTIL}"
fi

if [[ -n "${LOG_LEVEL_UPNP}" ]]; then
    CMD_LINE="$CMD_LINE -d upnp=${LOG_LEVEL_UPNP}"
fi

if [[ -n "${CODEC}" ]]; then
    echo "Setting CODEC to [${CODEC}] ..."
    CMD_LINE="$CMD_LINE -c ${CODEC}"
fi

if [[ -n "${LATENCY}" ]]; then
    echo "Setting LATENCY to [${LATENCY}] ..."
    CMD_LINE="$CMD_LINE -l ${LATENCY}"
fi

echo "NETWORK_SELECT=${NETWORK_SELECT}"
select_network="${NETWORK_SELECT}"
if [[ -z "${select_network}" ]]; then
    echo "ENABLE_AUTO_NETWORK=[${ENABLE_AUTO_NETWORK}]"
    if [[ -z "${ENABLE_AUTO_NETWORK}" ]] || [[ "${ENABLE_AUTO_NETWORK^^}" == "YES" ]] || [[ "${ENABLE_AUTO_NETWORK^^}" == "Y" ]]; then
        echo "Automatically setting network ..."
        auto_network_url="${AUTO_NETWORK_URL}"
        if [[ -z "${auto_network_url}" ]]; then
            auto_network_url=1.1.1.1
        fi
        select_network=$(ip route get $auto_network_url | grep -oP 'dev\s+\K[^ ]+')
        select_ip=$(ifconfig $select_network | sed -En 's/127.0.0.1//;s/.*inet (addr:)?(([0-9]*\.){3}[0-9]*).*/\2/p')
        chosen_network_argument="${select_network}"
        if [[ -z "${NETWORK_USE_IP}" ]] || [[ "${NETWORK_USE_IP^^}" == "YES" ]] || [[ "${NETWORK_USE_IP^^}" == "Y" ]]; then
            chosen_network_argument="${select_ip}"
        fi
        echo "Automatically setting network [Done]"
        CMD_LINE="$CMD_LINE -b ${chosen_network_argument}"
    elif [[ "${ENABLE_AUTO_NETWORK^^}" != "NO" ]] && [[ "${ENABLE_AUTO_NETWORK^^}" != "N" ]]; then
        echo "Invalid ENABLE_AUTO_NETWORK=[${ENABLE_AUTO_NETWORK}]"
        exit 1
    fi
else
    # use provided iface
    CMD_LINE="$CMD_LINE -b ${select_network}"
fi

echo "Command Line: ["$CMD_LINE"]"
if [[ $user_mode -eq 1 ]]; then
    echo "User mode enabled, PUID=[$PUID] PGID=[$PGID] USER_NAME=[$USER_NAME]"
    exec su - $USER_NAME -c "$CMD_LINE"
else
    echo "User mode disabled"
    eval "exec $CMD_LINE"
fi
