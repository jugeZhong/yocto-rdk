FILESEXTRAPATHS:prepend := "${RDK_SDK_UBOOT_DIR}:"
SRC_URI = "file://${RDK_SDK_UBOOT_DIR}/"

LICENSE = "GPL-2.0-only"
LIC_FILES_CHKSUM = "file://${RDK_SDK_UBOOT_DIR}/Licenses/gpl-2.0.txt;md5=b234ee4d69f5fce4486a80fdaf4a4263"

UBOOT_OUTPUT_DIR = "${WORKDIR}/build"

do_fetch[noexec] = "1"
do_unpack[noexec] = "1" 
do_patch[noexec] = "1"

do_configure:prepend() {
    if [ ! -d "${RDK_SDK_UBOOT_DIR}" ]; then
        bbfatal "RDK U-Boot directory not found: ${RDK_SDK_UBOOT_DIR}"
    fi
    
    if [ ! -f "${RDK_SDK_UBOOT_DIR}/Makefile" ]; then
        bbfatal "U-Boot Makefile not found in: ${RDK_SDK_UBOOT_DIR}"
    fi
    
	mkdir -p ${UBOOT_OUTPUT_DIR}

    rm -rf ${S}
    ln -sf ${RDK_SDK_UBOOT_DIR} ${S}
    
    bbnote "Using external U-Boot source from: ${RDK_SDK_UBOOT_DIR}"

    bbnote "Configuring U-Boot with external toolchain: ${TOOLCHAIN_PREFIX}"
    oe_runmake -C ${S} O=${UBOOT_OUTPUT_DIR} \
        ARCH=${UBOOT_ARCH} \
        CROSS_COMPILE=${TOOLCHAIN_PREFIX} \
        ${UBOOT_CONFIG}
	
}

do_compile() {
    bbnote "Compiling U-Boot..."
    oe_runmake -C ${S} O=${UBOOT_OUTPUT_DIR} \
        ARCH=${UBOOT_ARCH} \
        CROSS_COMPILE=${TOOLCHAIN_PREFIX} \
        all
    
    if [ ! -f "${UBOOT_OUTPUT_DIR}/u-boot.bin" ]; then
        bbfatal "U-Boot binary not found after compilation"
    fi
}