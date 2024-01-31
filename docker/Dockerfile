#
# This Dockerfile needs to be run from within the project/ directory (AKA ../../ from here)
# so that docker has access to all the files it needs. ie.
#
# $ docker build -t $DOCKER_IMAGE_NAME -f adamant_example/docker/Dockerfile .
#
# For best results use the ./build_image.sh and ./create_container.sh scripts
# provided in this directory.
#
FROM ghcr.io/lasp/adamant:latest as adamant_base

# Install elf2uf2
#
#   source: https://circuitdigest.com/microcontroller-projects/how-to-program-raspberry-pi-pico-using-c
#
#   # Install prerequisites:
#   sudo apt install git cmake gcc-arm-none-eabi gcc g++ libstdc++-arm-none-eabi-newlib
#   sudo apt-get install cmake make
#   sudo apt install automake autoconf build-essential texinfo libtool libftdi-dev libusb-1.0-0-dev
#    ^ The prepreqs for compiling elf2uf2 are already installed at this point,
#       but leaving this comment here for reference
#
FROM adamant_base AS install_elf2uf2
RUN DEBIAN_FRONTEND=noninteractive apt-get install -yq make cmake automake autoconf build-essential texinfo libtool libftdi-dev libusb-1.0-0-dev gcc-arm-none-eabi gcc g++ libstdc++-arm-none-eabi-newlib \
    && mkdir -p /root/pico \
    && cd /root/pico \
    && git clone -b master https://github.com/raspberrypi/pico-sdk.git \
    && cd /root/pico/pico-sdk/tools/elf2uf2 \
    && mkdir build \
    && cd build \
    && cmake .. \
    && make

# Construct the final image from the multi-step build images above:
FROM adamant_base AS final
LABEL org.opencontainers.image.source=https://github.com/lasp/adamant_example
LABEL org.opencontainers.image.description="Example project for the Adamant framework"
LABEL org.opencontainers.image.licenses=Apache-2.0
USER root
ENV BIN_DIR=/usr/local/bin
COPY --from=install_elf2uf2 /root/pico/pico-sdk/tools/elf2uf2/build/elf2uf2 $BIN_DIR

# Set up .bashrc to automatically activate the Adamant Example environment
RUN cp /root/.bashrc $HOME/.bashrc \
    && echo "cd $HOME && [ -f "~/adamant_example/env/activate" ] && source adamant_example/env/activate" >> $HOME/.bashrc \
    && chown -R $DOCKER_USER:$DOCKER_USER $HOME

# Make sure user is root at end.
USER root
