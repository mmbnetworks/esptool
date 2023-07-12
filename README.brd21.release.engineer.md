# Introduction

The overall idea here is to make this repo a stand-alone tooling that operates
only on the build system prepared binary package (without needing access to brd21 source tree)
which means it needs to host its own tooling to:

1. Sign plain binaries with HSM using espsecure
2. Stitch together the binaries into an mmb brd21 ota-binary package (similar to what ota_gen.sh do for us today)
3. Encrypt the ota-binary package using the esptool provided ota_encryption_gen.sh

# TODO
An imagined workflow looks like this

1. Get and extract a prod.secure tarball from the build system
2. call something like `prepare_signed_flasher_bundle.sh tme.sifton prod.secure <path-to-input-unsigned-tarbal> <name-of-output-signed-tarbal>`
 the script will:

 2.1. extract the `<input-unsigned-tarbal>`

 2.2. confirm that the contents contains
    2.2.1. the expected binaries (i.e. `tme.sifton` and `prod.secure` in the binary names)
    2.2.2. the expected key (i.e. pub key for ota-encrypted)

 2.3. sign using HSM (prompt for pin)
 2.4. call a helper script to make ota-binary (i.e. an improved ota_gen.sh)
 2.5. call a helper script to encrypt ota-binary (using a standalone copy of `ota_encryption_gen.sh`)

 2.6. re-tar up the prepared file into `<name-of-signed-tarbal>` and clean up any intermediate files

3. the `release engineer can then re-upload` the `<name-of-output-signed-tarbal>` back to S3 for further processing

So download, run-script and re-upload, which is much less error prone.
