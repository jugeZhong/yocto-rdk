#!/bin/bash

set -e

this_user="$(whoami)"
if [ "${this_user}" != "root" ]; then
	echo "[ERROR]: This script requires root privileges. Please execute it with sudo."
	exit 1
fi

# Get Ubuntu system version
ubuntu_version=$(grep -oP 'VERSION_ID="\K[0-9.]+' /etc/os-release | tr -d '"')

echo "Ubuntu version: $ubuntu_version"

general_deps="tzdata tree bc hashdeep kmod file wget curl cpio unzip rsync liblz4-tool jq"
build_deps="build-essential make cmake bison flex ccache zlib1g-dev libssl-dev libncurses-dev u-boot-tools device-tree-compiler cryptsetup-bin"
sparseimg_deps="android-sdk-libsparse-utils"
fatfs_deps="dosfstools mtools"
mtd_deps="mtd-utils"
extfs_deps="e2fsprogs"
python_deps="python3 python3-pip python3-pexpect python3 python3-pip python3-pexpect pylint xterm python3-subunit python3-setuptools python3-yaml libpython3-dev"
other_deps="gawk git-core diffstat texinfo gcc-multilib chrpath socat xz-utils debianutils iputils-ping libegl1-mesa libsdl1.2-dev mesa-common-dev zstd locales"

all_deps="${general_deps} ${build_deps} \
	${sparseimg_deps} ${fatfs_deps} ${mtd_deps} ${python_deps} ${other_deps}"

# Check the version and install software dependencies accordingly
if [[ $ubuntu_version == "22.04" ]]; then
	echo "[INFO]: Ubuntu 22.04, installing software dependencies..."
	apt-get install -y ${all_deps}
else
	echo "[ERROR]: Unsupported Ubuntu version: ${ubuntu_version}"
	exit 1
fi

echo "[INFO]: Installation completed!"

echo "[INFO]: Installation SDK!"
# Configuration parameters
SDK_VERSION="LNX6.1.83_PL5.1_V1.1.0"
DOWNLOAD_BASE_URL="https://archive.d-robotics.cc/downloads/sdk"
RDK_SDK_TARGET_DIR="rdk-sdk"
ARCHIVE_FILE="platform_source_code.tar.gz"
MD5_FILE="${ARCHIVE_FILE}.md5sum"

# Build complete URLs
DOWNLOAD_URL="${DOWNLOAD_BASE_URL}/${SDK_VERSION}/board_support_package/${ARCHIVE_FILE}"
MD5_URL="${DOWNLOAD_URL}.md5sum"

echo "Using SDK version: ${SDK_VERSION}"
echo "Download URL: ${DOWNLOAD_URL}"
echo "MD5 URL: ${MD5_URL}"

# Clean up old files (but keep archive if valid)
cleanup() {
    echo "Cleaning up old files..."
    rm -rf "${RDK_SDK_TARGET_DIR}"
    rm -f "${MD5_FILE}"
}

# Check if archive exists and is valid
check_existing_archive() {
    if [ -f "${ARCHIVE_FILE}" ]; then
        echo "Existing archive found: ${ARCHIVE_FILE}"
        
        # Download MD5 file if missing
        if [ ! -f "${MD5_FILE}" ]; then
            echo "MD5 file missing, downloading..."
            download_file "${MD5_URL}" "${MD5_FILE}" || return 1
        fi
        
        # Verify existing archive
        if verify_md5; then
            echo "Existing archive is valid. Skipping download."
            return 0
        else
            echo "Existing archive is invalid. Will redownload."
            rm -f "${ARCHIVE_FILE}"
            return 1
        fi
    fi
    return 1
}

# Download file function
download_file() {
    local url=$1
    local output=$2
    
    echo "Downloading: ${url}"
    if ! wget --show-progress --progress=bar:force:noscroll -qO "${output}" "${url}"; then
        echo "Error: Download failed - ${url}"
        return 1
    fi
    return 0
}

# Verify MD5 checksum
verify_md5() {
    echo "Verifying MD5 checksum..."
    
    # Calculate actual MD5
    local actual_md5
    actual_md5=$(md5sum "${ARCHIVE_FILE}" | cut -d' ' -f1)
    
    # Get expected MD5
    local expected_md5
    expected_md5=$(cat "${MD5_FILE}" | cut -d' ' -f1)
    
    if [ -z "${expected_md5}" ]; then
        echo "Error: MD5 file is empty or invalid format"
        return 1
    fi
    
    if [ "${actual_md5}" != "${expected_md5}" ]; then
        echo "Error: MD5 checksum verification failed!"
        echo "Expected: ${expected_md5}"
        echo "Actual: ${actual_md5}"
        return 1
    fi
    
    echo "MD5 verification successful: ${actual_md5}"
    return 0
}

# Extract archive
extract_archive() {
    echo "Extracting to directory: ${RDK_SDK_TARGET_DIR}"
    mkdir -p "${RDK_SDK_TARGET_DIR}"
    
    if ! tar -xzf "${ARCHIVE_FILE}" -C "${RDK_SDK_TARGET_DIR}"; then
        echo "Error: Extraction failed"
        return 1
    fi
    
    echo "Extraction completed"
    return 0
}

sdk_install() {
    # Clean up old extracted files
    cleanup
    
    # Check if valid archive already exists
    if ! check_existing_archive; then
        # Download main file
        if ! download_file "${DOWNLOAD_URL}" "${ARCHIVE_FILE}"; then
            exit 1
        fi
        
        # Download MD5 file
        if ! download_file "${MD5_URL}" "${MD5_FILE}"; then
            exit 1
        fi
        
        # Verify MD5
        if ! verify_md5; then
            exit 1
        fi
    fi
    
    # Extract archive
    if ! extract_archive; then
        exit 1
    fi
    
    echo "Operation completed successfully!"
}

sdk_install
echo "[INFO]: Installation SDK successfully!"

echo "[INFO]: Installation Yocto poky and meta-openembedded!"
# Configuration parameters
POKY_REPO="git://git.yoctoproject.org/poky.git"
POKY_BRANCH="scarthgap"
META_OE_REPO="git://git.openembedded.org/meta-openembedded"
META_OE_BRANCH="scarthgap"


# Clone Git repository if not exists
clone_repo() {
    local repo_url=$1
    local branch=$2
    local target_dir=$3
    
    if [ -d "${target_dir}" ]; then
        echo "Repository already exists: ${target_dir}"
        echo "Skipping clone. To update, run: git pull origin ${branch}"
        return 0
    fi
    
    echo "Cloning repository: ${repo_url} (branch: ${branch})"
    if ! git clone -b "${branch}" --depth 1 "${repo_url}" "${target_dir}"; then
        echo "Error: Failed to clone repository"
        return 1
    fi
    
    echo "Clone completed"
    return 0
}

yocto_install() {
    echo "=== Yocto Repository Setup ==="
    
    # Clone required repositories
    clone_repo "${POKY_REPO}" "${POKY_BRANCH}" "poky" || exit 1
    
    # Clone meta-openembedded
	clone_repo "${META_OE_REPO}" "${META_OE_BRANCH}" "meta-openembedded" || exit 1
    
    echo "=== Repository setup completed! ==="
    echo "Next steps:"
    echo "1. Set up Yocto environment: source poky/oe-init-build-env"
    echo "2. Configure your build"
}

yocto_install
echo "[INFO]: Installation Yocto poky and meta-openembedded successfully!"

echo "=== arm gnu toolchain Setup ==="
TOOLCHAIN_VERSION="11.3.rel1"
ARCHITECTURE="x86_64"
TARGET_ARCH="aarch64"
SYSROOT="none-linux-gnu"
TOOLCHAIN_FILE="rdk-sdk/platform_source_code/toolchain/arm-gnu-toolchain-${TOOLCHAIN_VERSION}-${ARCHITECTURE}-${TARGET_ARCH}-${SYSROOT}.tar.xz"

toolchain_install() {
	if [ -f "$TOOLCHAIN_FILE" ]; then
		echo "Toolchain file found"
		echo "  Version: $TOOLCHAIN_VERSION"
		echo "  Architecture: $ARCHITECTURE -> $TARGET_ARCH"
		echo "  System: $SYSROOT"
		local TARGET_DIR="/opt"

		sudo mkdir -p "$TARGET_DIR"
		
		echo "Extracting to $TARGET_DIR ..."
		sudo tar -xf "$TOOLCHAIN_FILE" -C "$TARGET_DIR"
		
		if [ $? -eq 0 ]; then
			echo "Extraction successful"
			
			TOOLCHAIN_DIR=$(find "$TARGET_DIR" -name "arm-gnu-toolchain-*" -type d | head -1)
			if [ -n "$TOOLCHAIN_DIR" ]; then
				echo "Toolchain location: $TOOLCHAIN_DIR"
				
				sudo chmod -R 755 "$TOOLCHAIN_DIR"
				
				if [ -f "$TOOLCHAIN_DIR/bin/${TARGET_ARCH}-${SYSROOT}-gcc" ]; then
					echo "Toolchain verification successful"
					echo "GCC version:"
					"$TOOLCHAIN_DIR/bin/${TARGET_ARCH}-${SYSROOT}-gcc" --version | head -1
				fi
			fi
		else
			echo "Extraction failed"
			exit 1
		fi
	else
		echo "File does not exist: $TOOLCHAIN_FILE"
		exit 1
	fi
}

toolchain_install
echo "=== Installation arm gnu toolchain successfully ==="