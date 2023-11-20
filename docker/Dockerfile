#
# This Dockerfile needs to be run from within the project/ directory (AKA ../../ from here)
# so that docker has access to all the files it needs. ie.
#
# $ docker build -t $DOCKER_IMAGE_NAME -f example/docker/Dockerfile .
#
# For best results use the ./build_image.sh and ./create_container.sh scripts
# provided in this directory.
#
FROM ubuntu:22.04 AS base

ENV DEBIAN_FRONTEND=noninteractive
ARG DOCKER_USER=user

# install common dependencies
RUN DEBIAN_FRONTEND=noninteractive apt-get update && DEBIAN_FRONTEND=noninteractive apt-get -yq install \
    software-properties-common \
    apt-utils \
    locales \
    curl \
    lsb-release \
    # openssh-server \
    sudo \
    python3 \
    git \
    build-essential \
    && DEBIAN_FRONTEND=noninteractive apt-get -yq clean

# ensure we have the en_US.UTF-8 locale available
RUN locale-gen en_US.UTF-8

# setup the user
RUN if ! getent passwd $DOCKER_USER; then useradd -d /home/$DOCKER_USER -m -s /bin/bash $DOCKER_USER; fi \
    && echo $DOCKER_USER:$DOCKER_USER | chpasswd \
    && echo "$DOCKER_USER ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers \
    && mkdir -p /etc/sudoers.d \
    && echo "$DOCKER_USER ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/$DOCKER_USER \
    && chmod 0440 /etc/sudoers.d/$DOCKER_USER

RUN rm /etc/apt/apt.conf.d/docker-clean

# Add environment variables:
ENV HOME=/home/$DOCKER_USER
ENV ENV_DIR=$HOME/env
ENV PROVISION_DIR=$ENV_DIR/provision
ENV BIN_DIR=/usr/local/bin
RUN mkdir -p $PROVISION_DIR

#
# Adamant add-on portion:
#
FROM base as adamant_base

# Copy files:
USER $DOCKER_USER
COPY example/docker/env/provision/bashrc.sh $HOME/.bashrc
COPY example/docker/env/provision/example.prf $HOME/.unison/example.prf
COPY adamant/env/provision/adamant.prf $HOME/.unison/adamant.prf

# Set up symlink to shared folder:
USER root
RUN if ! test -d /share; then mkdir /share; fi
RUN if ! test -d $HOME/share; then ln -sf /share $HOME/share; fi

# Install some base Adamant dependencies:
#
# Note: Due to this issue: 
#
#     https://bugs.python.org/issue40350
#     https://github.com/python/cpython/issues/84530
#
# We need to use python 3.7 until it is resolved.
# By default this version of Ubuntu uses 3.8 which
# exhibits the bug.
RUN cat /dev/zero | ssh-keygen -q -N "" \
    && echo "vm.swappiness = 0" > /etc/sysctl.conf \
    && sudo ln -sf /usr/lib/x86_64-linux-gnu/libreadline.so.8 /usr/lib/x86_64-linux-gnu/libreadline.so.7 \
    && DEBIAN_FRONTEND=noninteractive add-apt-repository -y ppa:linuxuprising/libpng12 \
    && DEBIAN_FRONTEND=noninteractive add-apt-repository -y ppa:deadsnakes/ppa \
    && apt install --reinstall -y software-properties-common \
    && add-apt-repository ppa:linuxuprising/libpng12 \
    && add-apt-repository ppa:deadsnakes/ppa \
    && DEBIAN_FRONTEND=noninteractive apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -yq socat graphviz libpng12-0 gawk xxd time psmisc python3.7 python3.7-venv python3.7-dev \
    && DEBIAN_FRONTEND=noninteractive apt install -yq `DEBIAN_FRONTEND=noninteractive apt --assume-no install texlive-full | \
         awk '/The following additional packages will be installed/{f=1;next} /Suggested packages/{f=0} f' | \
         tr ' ' '\n' | \
         grep -vP 'doc$' | \
         grep -vP 'texlive-lang' | \
         grep -vP 'texlive-fonts' | \
         grep -vP 'latex-cjk' | \
         tr '\n' ' '` \
    && DEBIAN_FRONTEND=noninteractive apt install -yq texlive-lang-english texlive-lang-european texlive-fonts-recommended \
    && DEBIAN_FRONTEND=noninteractive apt-get -yq clean

# Install python:
# Do to this issue: https://bugs.python.org/issue40350
# We need to use python 3.7 until it is resolved.
# By default this version of Ubuntu uses 3.8 which
# exhibits the bug.
ENV PYTHON_ENV_DIR=$ENV_DIR/python
COPY adamant/env/provision $ENV_DIR/requirements
RUN DEBIAN_FRONTEND=noninteractive sudo apt-get -yq install python3.7 \
    && python3.7 -m venv $PYTHON_ENV_DIR \
    && . $PYTHON_ENV_DIR/bin/activate \
    && pip3.7 install --upgrade pip \
    && pip3.7 install wheel \
    && pip3.7 install -r $ENV_DIR/requirements/requirements1.txt \
    && pip3.7 install -r $ENV_DIR/requirements/requirements2.txt

# Install unison:
FROM base AS install_unison
RUN DEBIAN_FRONTEND=noninteractive sudo apt-get install -yq wget ocaml make \
    && cd $PROVISION_DIR \
    && git clone https://github.com/bcpierce00/unison \
    && cd $PROVISION_DIR/unison \
    && git fetch --tags \
    && git checkout v2.53.3 \
    && make

# Install redo:
FROM base AS install_redo
ENV STACK_ROOT=/root/.stack
RUN DEBIAN_FRONTEND=noninteractive sudo apt-get install -yq wget \
    && wget -qO- https://get.haskellstack.org/ | sh \
    && git config --global core.autocrlf false \
    && git clone https://github.com/dinkelk/redo.git $PROVISION_DIR/redo \
    && $PROVISION_DIR/redo/do $PROVISION_DIR/redo/all

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
FROM base AS install_elf2uf2
RUN DEBIAN_FRONTEND=noninteractive sudo apt-get install -yq make cmake \
    && mkdir -p $PROVISION_DIR/pico \
    && cd $PROVISION_DIR/pico \
    && git clone -b master https://github.com/raspberrypi/pico-sdk.git \
    && cd $PROVISION_DIR/pico/pico-sdk/tools/elf2uf2 \
    && mkdir build \
    && cd build \
    && cmake .. \
    && make

# Install Alire:
FROM base AS install_alire
ENV ALIRE_VERSION="1.2.2"
ENV ALIRE_FILE=alr-$ALIRE_VERSION-bin-x86_64-linux.zip
ENV ALIRE_URL=https://github.com/alire-project/alire/releases/download/v$ALIRE_VERSION/$ALIRE_FILE
RUN DEBIAN_FRONTEND=noninteractive sudo apt-get install -yq wget unzip \
    && mkdir -p $PROVISION_DIR/alire \
    && cd $PROVISION_DIR/alire \
    && wget $ALIRE_URL \
    && rm -rf bin \
    && unzip $ALIRE_FILE \
    && cp -r $PROVISION_DIR/alire/bin/alr $BIN_DIR

# Install GNAT tools like gnatpp and gnatmetric:
FROM install_alire AS install_libadalang
RUN mkdir -p $PROVISION_DIR/libadalang \
    && cd $PROVISION_DIR/libadalang \
    && git clone https://github.com/dinkelk/libadalang_tool_builder.git \
    && cd libadalang_tool_builder \
    && alr -n build --release \
    && mkdir tools \
    && sh install.sh tools

# Install sequence builder:
FROM base AS install_sequence_builder
RUN cd $PROVISION_DIR\
    && DEBIAN_FRONTEND=noninteractive sudo apt-get install -yq wget unzip \
    && wget https://github.com/lasp/adamant/releases/download/v0.0.0/adamant_seq.zip \
    && unzip adamant_seq.zip

#
# This build stage increases the docker image size by several GB. Delaying the
# configuration of the Ada dependencies to the first time the container is
# created only adds about 1 minute to the configuration time. So instead of
# adding the "install_ada_deps" to the base image, we delay this part of the
# configuration until the container is created by the user.
#
#  FROM install_alire AS install_ada_deps
#  USER root
#  COPY adamant $HOME/adamant
#  COPY example $HOME/example
#  RUN chown -R $DOCKER_USER:$DOCKER_USER $HOME
#
#  # Install Adamant Ada dependencies:
#  USER $DOCKER_USER
#  RUN cd $HOME/adamant \
#      && alr -n build --release \
#      && alr -n toolchain --select gnat_native \
#      && alr -n toolchain --select gprbuild
#
#  # Install Example Ada dependencies:
#  RUN cd $HOME/example \
#      && alr -n build --release
#

# Construct the final image from the multi-step build images above:
FROM adamant_base AS final
LABEL org.opencontainers.image.source=https://github.com/lasp/adamant
LABEL org.opencontainers.image.description="Development environment for the Adamant framework"
LABEL org.opencontainers.image.licenses=Apache-2.0
USER root
COPY --from=install_unison $PROVISION_DIR/unison/src/unison $BIN_DIR
COPY --from=install_unison $PROVISION_DIR/unison/src/unison-fsmonitor $BIN_DIR
COPY --from=install_redo $PROVISION_DIR/redo/bin/* $BIN_DIR
COPY --from=install_alire $PROVISION_DIR/alire/bin/alr $BIN_DIR
COPY --from=install_elf2uf2 $PROVISION_DIR/pico/pico-sdk/tools/elf2uf2/build/elf2uf2 $BIN_DIR
COPY --from=install_libadalang $PROVISION_DIR/libadalang/libadalang_tool_builder/tools/* $BIN_DIR
COPY --from=install_sequence_builder $PROVISION_DIR/adamant_seq/bin/* $BIN_DIR
# COPY --from=install_ada_deps $HOME/.config $HOME/.config
RUN chown -R $DOCKER_USER:$DOCKER_USER $HOME

# Make sure user is root at end.
USER root
