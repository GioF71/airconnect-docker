# airconnect-docker

A docker image for [AirConnect](https://github.com/philippe44/AirConnect).  
The latest images include version [1.8.3](https://github.com/philippe44/AirConnect/releases/tag/1.8.3).  

## References

This is based on [this project](https://github.com/philippe44/AirConnect) by [philippe44](https://github.com/philippe44).  
It will let you use your upnp renderers (including those created with [upmpdcli](https://github.com/GioF71/upmpdcli-docker) and [mpd](https://github.com/giof71/mpd-alsa-docker)) and your Chromecast devices as AirPlay devices.  

## Links

REPOSITORY|DESCRIPTION
:---|:---
Source code|[GitHub](https://github.com/GioF71/airconnect-docker)
Docker images|[Docker Hub](https://hub.docker.com/r/giof71/airconnect)

## Build

Simply build using the following:

```
docker build . -t giof71/airconnect:latest
```

## Configuration

Configuration is available through a set of environment variables.  
There are currently just a few variables available to set, but more will come as soon as possible.  

VARIABLE|DESCRIPTION
:---|:---
PUID|Group used to run the application, defaults to `1000`
PGID|Group used to run the application, defaults to `1000`
PREFER_STATIC|Prefer `-static` version of the executable, defaults to `no`
AIRCONNECT_MODE|AirConnect mode: `upnp` or `cast`, defaults to `upnp`
CODEC|Format used to send HTTP audio, refer to the AirConnect [documentation](https://github.com/philippe44/AirConnect)
LATENCY|Value for argument `-l`, set to `1000:2000` for Sonos and Heos players
CONFIG_FILE_PREFIX|Prefix for the config file, empty by default
LOG_LEVEL_ALL|Enables log of type `all` using the provided value
LOG_LEVEL_MAIN|Enables log of type `main` using the provided value
LOG_LEVEL_UTIL|Enables log of type `util` using the provided value
LOG_LEVEL_UPNP|Enables log of type `upnp` using the provided value
LOG_LEVEL_RAOP|Enables log of type `raop` using the provided value
ENABLE_AUTO_NETWORK|Allows to automatically set NETWORK_SELECT, defaults to `yes`, but this does not override an explicitly set `NETWORK_SELECT` variable anyway
NETWORK_SELECT|Sets the network interface or ip and optionally port
AUTO_NETWORK_URL|Used for selecting the network to use, defaults to `1.1.1.1`
NETWORK_USE_IP|Use ip instead of network card for `-b`, defaults to `yes`

## Run

Simple docker-compose files below.

### UPnP mode

```
---
version: "3"

volumes:
  config:

services:
  airconnect:
    image: giof71/airconnect:latest
    container_name: airconnect-upnp
    network_mode: host
    environment:
      - PUID=1000
      - PGID=1000
      - AIRCONNECT_MODE=upnp
    volumes:
      - config:/config
    restart: unless-stopped
```

### Chromecast mode

```
---
version: "3"

volumes:
  config:

services:
  airconnect:
    image: giof71/airconnect:latest
    container_name: airconnect-cast
    network_mode: host
    environment:
      - PUID=1000
      - PGID=1000
      - AIRCONNECT_MODE=cast
    volumes:
      - config:/config
    restart: unless-stopped
```

## Changelog

The changelog of the upstream project is available [here](https://github.com/philippe44/AirConnect/blob/master/CHANGELOG).  

DATE|DESCRIPTION
:---|:---
2024-03-15|Bump to version [1.8.3](https://github.com/philippe44/AirConnect/releases/tag/1.8.3)
2024-03-11|Prefer ip over iface for the select network interface
2024-03-09|Auto select network interface (see [#3](https://github.com/GioF71/airconnect-docker/issues/3))
2024-01-26|Add support for log levels
2024-01-15|Bump to version [1.7.0](https://github.com/philippe44/AirConnect/releases/tag/1.7.0)
2024-01-09|Bump to version [1.6.3](https://github.com/philippe44/AirConnect/releases/tag/1.6.3)
2023-12-27|Bump to version [1.6.2](https://github.com/philippe44/AirConnect/releases/tag/1.6.2)
2023-12-26|Bump to version [1.6.1](https://github.com/philippe44/AirConnect/releases/tag/1.6.1)
2023-12-18|Bump to version [1.6.0](https://github.com/philippe44/AirConnect/releases/tag/1.6.0)
2023-12-05|Add support for LATENCY (see [#1](https://github.com/GioF71/airconnect-docker/issues/1))
2023-12-05|Bump to version [1.5.4](https://github.com/philippe44/AirConnect/releases/tag/1.5.4)
2023-12-02|Bump to version [1.5.3](https://github.com/philippe44/AirConnect/releases/tag/1.5.3)
2023-11-28|Bump to version [1.5.0](https://github.com/philippe44/AirConnect/releases/tag/1.5.0)
2023-11-22|First working release
