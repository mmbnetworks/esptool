# What is this branch for?

We took esptool.py from upstream and applied:

- A workaround to enable image signing with NitroKey HSM2
- A way to prompt for HSM Pin instead of plaintext data in config files
- A collection of scripts to make this branch a standalone `release engineer` tooling for MMB BRD21 `prod.secure` binary release
  - See `README.brd21.release.engineer.md` in this repo for more details

# Original Upstream README.md below
# esptool.py

A Python-based, open-source, platform-independent utility to communicate with the ROM bootloader in Espressif chips.

[![Test esptool](https://github.com/espressif/esptool/actions/workflows/test_esptool.yml/badge.svg?branch=master)](https://github.com/espressif/esptool/actions/workflows/test_esptool.yml) [![Build esptool](https://github.com/espressif/esptool/actions/workflows/build_esptool.yml/badge.svg?branch=master)](https://github.com/espressif/esptool/actions/workflows/build_esptool.yml)

## Documentation

Visit the [documentation](https://docs.espressif.com/projects/esptool/) or run `esptool.py -h`.

## Contribute

If you're interested in contributing to esptool.py, please check the [contributions guide](https://docs.espressif.com/projects/esptool/en/latest/contributing.html).

## About

esptool.py was initially created by Fredrik Ahlberg (@[themadinventor](https://github.com/themadinventor/)), and later maintained by Angus Gratton (@[projectgus](https://github.com/projectgus/)). It is now supported by Espressif Systems. It has also received improvements from many members of the community.

## License

This document and the attached source code are released as Free Software under GNU General Public License Version 2 or later. See the accompanying [LICENSE file](https://github.com/espressif/esptool/blob/master/LICENSE) for a copy.
