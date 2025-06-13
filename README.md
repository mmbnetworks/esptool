# DEPRECATED!

The `/release-engineer-tools` folder in this repo slated to be
migrated into https://github.com/mmbnetworks/mmb-brd2x-build-support

This repo will eventually only contains:

esptool from upstream at v4.7 and applied our fixes:
- A workaround to enable image signing with NitroKey HSM2
- A way to prompt for HSM Pin instead of plaintext data in config files


# How We use it today
- A collection of scripts to make this branch a standalone `release engineer`
  tooling for MMB BRD2x `prod.secure` binary release
  - See `README.brd21.release.engineer.md` in this repo for more details
