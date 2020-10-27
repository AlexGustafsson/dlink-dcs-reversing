# D-Link DCS reversing
### An effort to simplify firmware analysis and firmware updating on D-Link's DCS line of products
***

## Project goal

The short-term goal of this project is to provide the necessary tools to easily analyze and modify D-Link's firmware for its DCS line of products (such as their network cameras).

A long-term goal is to be able to provide an alternative firmware with only the bare essentials to use the camera in order to fully disable all cloud aspects of the camera and to potentially make it HomeKit-compatible.

## What's in the box

### Scripts

#### Firmware

The `./scripts/download-firmware.sh` script downloads the firmware for a specific product. For example, one can download the latest firmware for the DCS-936L like so:

```sh
./scripts/download-firmware.sh <model> <output directory> [firmware index]
./scripts/download-firmware.sh dcs-936l firmware 1
```

The `./scripts/unpack-firmware.sh` script decrypts, unpacks and carves date from the firmware file. It can be used like so:

```sh
./scripts/unpack-firmware.sh <path to firmware> <output directory>
./scripts/unpack-firmware.sh firmware/DCS-936L_fw_revA1_1-07-04_eu_multi_20180918.zip dump
```

Example (shallow) directory structure for the unpacking script:

```
❯ tree -L 4 -d dump/
dump/
├── carved
│   └── _update.extracted
│       ├── squashfs-root
│       └── squashfs-root-0
│           ├── empty -> /tmp
│           ├── lib -> /tmp
│           ├── lock -> /tmp
│           ├── log -> /tmp
│           ├── run -> /tmp
│           ├── shares
│           ├── tmp -> /tmp
│           └── www
└── extracted
```

### Tools

The `./tools` directory contains dockerized tools such as Binwalk. The tools can be built and used using the following script:

```sh
./tools/build.sh
docker run -it binwalk
```

## Previous art

https://github.com/bmork/defogger

## Contributing

Any contribution is welcome. If you're not able to code it yourself, perhaps someone else is - so post an issue if there's anything on your mind.

### Development

Clone the repository:
```
git clone https://github.com/AlexGustafsson/dlink-dcs-reversing && cd dlink-dcs-reversing
```
