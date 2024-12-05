#!/bin/zsh

# Exit on error
set -e

# Number of cores when running make
JNUM=$(nproc)

# Install dependencies
SDK_DEPS="git gcc g++ cmake python3 build-essential gcc-arm-none-eabi libnewlib-arm-none-eabi libstdc++-arm-none-eabi-newlib pkg-config"
OPENOCD_DEPS="gdb-multiarch automake autoconf build-essential texinfo libtool libftdi-dev libusb-1.0-0-dev bison flex gperf patchutils bc zlib1g-dev ninja-build libslirp-dev libmpc-dev libmpfr-dev libgmp-dev gawk libhidapi-dev"
UART_DEPS="minicom"

# Build full list of dependencies
DEPS="$SDK_DEPS $OPENOCD_DEPS $UART_DEPS"

# Installing dependencies
echo "Installing Dependencies"
sudo apt update
sudo apt upgrade -y
sudo apt install -y ${(z)DEPS}

# Where will the output go?
PICO_HOME="${HOME}/pico"
PICO_RC="${HOME}/.pico_rc"
ZSH_RC="${HOME}/.zshrc"

# Create pico directory to put everything in
if [ -d $PICO_HOME ]; then
	echo "$PICO_HOME already exists"
else
	mkdir -p $PICO_HOME
	echo "Created $PICO_HOME."
	echo "export PICO_HOME=$PICO_HOME" >> $PICO_RC
	echo "source $PICO_RC" >> $ZSH_RC
fi
cd $PICO_HOME

# Clone sw repos
GITHUB_PREFIX="https://github.com/raspberrypi/"
GITHUB_SUFFIX=".git"
SDK_BRANCH="master"

for REPO in sdk examples extras playground
do
    DEST="$PICO_HOME/pico-$REPO"

    if [ -d $DEST ]; then
        echo "$DEST already exists so skipping"
    else
        REPO_URL="${GITHUB_PREFIX}pico-${REPO}${GITHUB_SUFFIX}"
        echo "Cloning $REPO_URL"
        git clone -b $SDK_BRANCH $REPO_URL

        # Any submodules
        cd $DEST
        git submodule update --init
        cd $PICO_HOME

        # Define PICO_SDK_PATH to $PICO_RC
        VARNAME="PICO_${REPO:u}_PATH"
        echo "Adding $VARNAME to $PICO_RC"
        echo "export $VARNAME=$DEST" >> $PICO_RC
        export ${VARNAME}=$DEST
    fi
done

cd $PICO_HOME

# Pick up new variables we just defined
source $PICO_RC


# Debugprobe and picotool
for REPO in debugprobe picotool
do
    DEST="$PICO_HOME/$REPO"
    REPO_URL="${GITHUB_PREFIX}${REPO}${GITHUB_SUFFIX}"
    git clone $REPO_URL

    # Build both
    cd $DEST
    git submodule update --init
    mkdir build
    cd build
    cmake ../
    make -j$JNUM

    if [[ "$REPO" == "picotool" ]]; then
        echo "Installing picotool to /usr/local/bin/picotool"
        sudo cp picotool /usr/local/bin/
        echo "export PICOTOOL_FETCH_FROM_GIT_PATH=$PICO_HOME/picotool" >> $PICO_RC
        export PICOTOOL_FETCH_FROM_GIT_PATH=$PICO_HOME/picotool
        sudo cp ../udev/99-picotool.rules /etc/udev/rules.d/
    fi

    cd $PICO_HOME
done


# Install OpenOCD
if [ -d openocd ]; then
    echo "openocd already exists so skipping"
    SKIP_OPENOCD=1
fi

if [[ "$SKIP_OPENOCD" == 1 ]]; then
    echo "Won't build OpenOCD"
else
    # Build OpenOCD
    echo "Building OpenOCD"
    cd $PICO_HOME
    OPENOCD_CONFIGURE_ARGS="--enable-ftdi --enable-sysfsgpio --enable-bcm2835gpio --disable-werror"

    git clone "${GITHUB_PREFIX}openocd${GITHUB_SUFFIX}" --depth=1
    cd openocd
    ./bootstrap
    ./configure ${(z)OPENOCD_CONFIGURE_ARGS}
    make -j$JNUM
    sudo make install
fi

cd $PICO_HOME


# Build blink and uart/hello_uart for pico2
cd $PICO_EXAMPLES_PATH
build_dir=build_$board
mkdir $build_dir
cd $build_dir

cmake ../ -DPICO_BOARD=pico2 -DPICO_PLATFORM=rp2350 -DPICO_STDIO_USB=1 -DCMAKE_BUILD_TYPE=Debug

for e in blink hello_world
do
	echo "Building $e for $board"
	cd $e
	make -j$JNUM
	cd ..
done

cd $PICO_HOME

