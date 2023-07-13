#!/bin/bash
#
# ------------------------------------------------------------------------------
# This script is meant to automate and guard rail the work of a release engineer
# to take an unsigned-flasher-bundle produced by the "prod.secure" build plan
# and make it into signed-flasher-bundle that is then used by:
# - production systems in the factory
# - field customers to perform OTA Software Update
#
# The high level steps are:
#
# 1. Extract and validate the input
# 2. Sign binaries used for production systems
# 3. Generate encrypted ota for field customer upgrade
# 4. Re-archive the updated package
# ------------------------------------------------------------------------------

# BEFORE YOU BEGIN
# ------------------------------------------------------------------------------
# 1. Make sure you have the HSM Key plugged in
# 2. Make sure you remember your HSM PIN
# 3. To re-test the connection to the HSM, you can do:
#    gpgconf --kill all && sudo systemctl restart pcscd && pkcs11-tool -O

# ------------------------------------------------------------------------------
# Set CLI arguments to know values
# ------------------------------------------------------------------------------
unsetVal="unset"
productVariantArg=$unsetVal
buildVariantArg=$unsetVal
versionArg=$unsetVal
unsignedFlasherBundleArg=$unsetVal
signedFlasherBundleArg=$unsetVal
verboseArg=$unsetVal

# Parse for CLI arguments
# ------------------------------------------------------------------------------

if [ "$#" -ne 5 ]; then
    printf "Arguments Count: $# is insufficient\n\n"
    printf "ArgList: <product-variant>  <build-variant>  <expected-version>  <input-flasher-bundle>  <output-flasher-bundle>\n"
    printf "Example:    tme.sifton        prod.secure         0.9.4            bundle-unsigned.tar      bundle-signed.tar\n"
    exit 1
else
    productVariantArg=$1
    buildVariantArg=$2
    versionArg=$3
    unsignedFlasherBundleArg=$4
    signedFlasherBundleArg=$5
fi

# Tracer prints for Arg parsing
# ------------------------------------------------------------------------------
verboseArg=YES # use verbose mode by default while developing

if [ $verboseArg == "YES" ]; then
    printf "product variant         = ${productVariantArg}\n"
    printf "build variant           = ${buildVariantArg}\n"
    printf "expected version        = ${versionArg}\n"
    printf "unsigned flasher bundle = ${unsignedFlasherBundleArg}\n"
    printf "signed flasher bundle   = ${signedFlasherBundleArg}\n"
fi

# Access and extract input-flasher-bundle to our workingDir
# ------------------------------------------------------------------------------
workingDir=flasher_bundle

if [ ! -f "$unsignedFlasherBundleArg" ]; then
	printf "input-flasher-bundle: $unsignedFlasherBundleArg not found\n"
    exit 1
else
    # Sanitize any old content and extract a new copy
    printf "\n -------- Extracting input flasher bundle ----------------------\n"
    rm -rf $workingDir && tar -xvf $unsignedFlasherBundleArg
    if [ $? -ne 0 ]; then
        printf "\n input-flasher-bundle: extraction [ERR]\n"
        exit 1
    fi
fi

# Validate contents of input-flasher-bunlde to assist the release engineer
# ------------------------------------------------------------------------------
printf "\n -------- Validating input flasher bundle -------------------\n"

# Should have the expected unsigned bootloader
# for example: flasher_bundle/bootloader/tme.sifton.bootloader.unsigned.bin
bootloaderInputBin="$workingDir/bootloader/$productVariantArg.bootloader.unsigned.bin"

if [ ! -f "$bootloaderInputBin" ]; then
	printf "input-flasher-bundle: $bootloaderInputBin not found\n"
    exit 1
fi

# Should have the expected unsigned application, for example:
# for example: flasher_bundle/tme.sifton.application.unsigned.bin
applicationInputBin="$workingDir/$productVariantArg.application.unsigned.bin"

if [ ! -f "$applicationInputBin" ]; then
	printf "input-flasher-bundle: $applicationInputBin not found\n"
    exit 1
fi

# Should have the expected version_vars.txt that matches the expected version
# for example: flasher_bundle/version_vars.txt
versionInputTxt="$workingDir/version_vars.txt"

if [ ! -f "$versionInputTxt" ]; then
	printf "input-flasher-bundle: $versionInputTxt not found\n"
    exit 1
else
    inputVersion=`grep VERSION= $versionInputTxt | cut -d = -f 2 | sed -e 's/^"//' -e 's/"$//'`
    inputGitHash=`grep GIT_HASH= $versionInputTxt | cut -d = -f 2 | sed -e 's/^"//' -e 's/"$//'`

    if [ $inputVersion == $versionArg ]; then
        printf "\n version: Found VERSION = $inputVersion ; GIT_HASH = $inputGitHash [OK]\n"
    else
        printf "\n version: $inputVersion != $versionArg (expected) [ERR]\n"
        exit 1
    fi
fi

# Should have the expected OTA encryption public key
# for example: flasher_bundle/esp32_swu_encryption_key.pub.pem
swuOTAEncryptionPubKey="$workingDir/esp32_swu_encryption_key.pub.pem"

if [ ! -f "$swuOTAEncryptionPubKey" ]; then
	printf "input-flasher-bundle: $swuOTAEncryptionPubKey not found\n"
    exit 1
fi

# Past this point all necessary input to do the work is accounted for and the
# variables that holds their path can be used in subsequent steps
# ------------------------------------------------------------------------------

# Sign the binaries
# ------------------------------------------------------------------------------
printf "\n-------- Sign binaries with HSM -----------------------------------\n"

# Common espseucre CLI args
espsecureCLIArg="sign_data  --version 2 --hsm --hsm-config brd21-hsm-config.conf"

# Sign the bootloader (will prompt for HSM PIN)
bootloaderSignedBin="$workingDir/bootloader/$productVariantArg.bootloader.signed.bin"

python3 -m espsecure $espsecureCLIArg --output $bootloaderSignedBin $bootloaderInputBin
if [ $? -eq 0 ]; then
    printf "\n bootloader: HSM sign [OK]\n"
else
    printf "\n bootloader: HSM sign [ERR]\n"
    exit 1
fi

# Sign the application (will prompt for HSM PIN)

applicationSignedBin="$workingDir/$productVariantArg.application.signed.bin"

python3 -m espsecure $espsecureCLIArg --output $applicationSignedBin $applicationInputBin
if [ $? -eq 0 ]; then
    printf "\n application: HSM sign [OK]\n"
else
    printf "\n application: HSM sign [ERR]\n"
    exit 1
fi


# Generate encrypted SWU OTA binary
# ------------------------------------------------------------------------------

# Generate SWU OTA (hint: add --verbose to CLI args if you run into issues here)
otaGenScript="release-engineer-tools/brd21-swu-ota-generator/mmb/ota_gen.sh"
swuOTAUnSignedBin="$workingDir/ota-unsigned.bin"
$otaGenScript --application=$applicationSignedBin --versionfile=$versionInputTxt --output=$swuOTAUnSignedBin
if [ $? -eq 0 ]; then
    printf "\n ota gen: Unsigned SWU OTA [OK]\n"
else
    printf "\n ota gen: Unsigned SWU OTA [ERR]\n"
    exit 1
fi

# Encrypt SWU OTA (output name sample: ota-encrypted-tme.sifton-prod.secure-0.9.2-5ab3cbf.bin)
espSWUEncryptionTool="release-engineer-tools/brd21-swu-ota-generator/espressif/esp_enc_img_gen.py"
swuOTASignedBin="$workingDir/ota-encrypted-$productVariantArg-$buildVariantArg-$inputVersion-$inputGitHash.bin"
python $espSWUEncryptionTool encrypt $swuOTAUnSignedBin $swuOTAEncryptionPubKey $swuOTASignedBin
if [ $? -eq 0 ]; then
    printf "\n ota encrypt: Encrypting SWU OTA [OK]\n"
    rm -f $swuOTAUnSignedBin # Sanitize so we do not have unsigned ota packages leftover
else
    printf "\n ota encrypt: Encrypting SWU OTA [ERR]\n"
    exit 1
fi

# Package up the signed flasher bundle
# ------------------------------------------------------------------------------
rm -f $signedFlasherBundleArg # remove any stale copy
tar -caf $signedFlasherBundleArg $workingDir # generate a new archive
if [ $? -eq 0 ]; then
    printf "\n  output bundle: $signedFlasherBundleArg generation complete [OK]\n"
else
    printf "\n  output bundle: $signedFlasherBundleArg generation complete [ERR]\n"
    exit 1
fi

# Let the release engineer know where the file is so they can re-upload it
printf "\n ALL DONE, please upload $signedFlasherBundleArg back to build system\n"
