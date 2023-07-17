# Introduction

The overall idea here is to make this repo a stand-alone tooling that operates
only on the build system prepared binary package (without needing access to brd21 source tree)
which means it needs to host its own tooling to:

1. Sign plain binaries with HSM using espsecure
2. Stitch together the binaries into an mmb brd21 ota-binary package (similar to what ota_gen.sh do for us today)
3. Encrypt the ota-binary package using the esptool provided ota_encryption_gen.sh

# Quick start guide
1. Once we have an unsigned flasher bundle from the build system
2. Activate the python virtual environment in this repo:

>```source bin/activate```

3. Connect your HSM to the PC and test its connectivity:

>```gpgconf --kill all && sudo systemctl restart pcscd && pkcs11-tool -O```

4. run the `prepare-signed-flasher-bundle.sh` script to create the signed flasher
like this:

>``` release-engineer-tools/prepare-signed-flasher-bundle.sh tme.sifton prod.secure 0.9.2 ~/path-to/unsigned-input.tar```

the script will take you through the process and prompt for HSM pin and finally
emit the name of the signed flasher bundle binary

for example `flasher-bundle-tme.sifton-prod.secure-0.9.2-5ab3cbf-signed.tar`