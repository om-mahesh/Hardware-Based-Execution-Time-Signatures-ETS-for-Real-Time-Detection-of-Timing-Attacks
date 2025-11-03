#!/bin/bash
# setup_toolchain.sh
# 
# Script to download and install RISC-V GCC toolchain for Windows/Linux/macOS

set -e

echo "=========================================="
echo "RISC-V Toolchain Setup for ETS Project"
echo "=========================================="

# Detect OS
OS="$(uname -s)"
case "${OS}" in
    Linux*)     PLATFORM=Linux;;
    Darwin*)    PLATFORM=Mac;;
    CYGWIN*|MINGW*|MSYS*)    PLATFORM=Windows;;
    *)          PLATFORM="UNKNOWN:${OS}"
esac

echo "Detected platform: ${PLATFORM}"

# Set toolchain directory
TOOLCHAIN_DIR="$(pwd)/riscv-toolchain"
mkdir -p ${TOOLCHAIN_DIR}

# Download prebuilt toolchain
if [ "${PLATFORM}" == "Linux" ]; then
    echo "Downloading RISC-V toolchain for Linux..."
    TOOLCHAIN_URL="https://github.com/xpack-dev-tools/riscv-none-elf-gcc-xpack/releases/download/v13.2.0-2/xpack-riscv-none-elf-gcc-13.2.0-2-linux-x64.tar.gz"
    TOOLCHAIN_FILE="riscv-gcc-linux.tar.gz"
    
    wget ${TOOLCHAIN_URL} -O ${TOOLCHAIN_FILE}
    tar -xzf ${TOOLCHAIN_FILE} -C ${TOOLCHAIN_DIR} --strip-components=1
    rm ${TOOLCHAIN_FILE}
    
elif [ "${PLATFORM}" == "Mac" ]; then
    echo "Downloading RISC-V toolchain for macOS..."
    TOOLCHAIN_URL="https://github.com/xpack-dev-tools/riscv-none-elf-gcc-xpack/releases/download/v13.2.0-2/xpack-riscv-none-elf-gcc-13.2.0-2-darwin-x64.tar.gz"
    TOOLCHAIN_FILE="riscv-gcc-mac.tar.gz"
    
    curl -L ${TOOLCHAIN_URL} -o ${TOOLCHAIN_FILE}
    tar -xzf ${TOOLCHAIN_FILE} -C ${TOOLCHAIN_DIR} --strip-components=1
    rm ${TOOLCHAIN_FILE}
    
elif [ "${PLATFORM}" == "Windows" ]; then
    echo "Downloading RISC-V toolchain for Windows..."
    TOOLCHAIN_URL="https://github.com/xpack-dev-tools/riscv-none-elf-gcc-xpack/releases/download/v13.2.0-2/xpack-riscv-none-elf-gcc-13.2.0-2-win32-x64.zip"
    TOOLCHAIN_FILE="riscv-gcc-windows.zip"
    
    curl -L ${TOOLCHAIN_URL} -o ${TOOLCHAIN_FILE}
    unzip -q ${TOOLCHAIN_FILE} -d ${TOOLCHAIN_DIR}
    rm ${TOOLCHAIN_FILE}
    
else
    echo "ERROR: Unsupported platform: ${PLATFORM}"
    echo "Please manually install RISC-V GCC from:"
    echo "https://github.com/xpack-dev-tools/riscv-none-elf-gcc-xpack/releases/"
    exit 1
fi

# Verify installation
RISCV_GCC="${TOOLCHAIN_DIR}/bin/riscv-none-elf-gcc"
if [ -f "${RISCV_GCC}" ]; then
    echo ""
    echo "✓ Toolchain installed successfully!"
    echo ""
    ${RISCV_GCC} --version
    echo ""
    echo "To use the toolchain, add to your PATH:"
    echo "  export PATH=\"${TOOLCHAIN_DIR}/bin:\$PATH\""
    echo ""
    echo "Or source the provided environment script:"
    echo "  source $(pwd)/env.sh"
else
    echo "ERROR: Toolchain installation failed!"
    exit 1
fi

# Create environment script
cat > env.sh << EOF
#!/bin/bash
# Source this file to set up RISC-V toolchain environment
export PATH="${TOOLCHAIN_DIR}/bin:\$PATH"
export RISCV="${TOOLCHAIN_DIR}"
echo "RISC-V toolchain environment configured"
echo "GCC: \$(riscv-none-elf-gcc --version | head -n1)"
EOF

chmod +x env.sh

echo "=========================================="
echo "Setup complete!"
echo "=========================================="

