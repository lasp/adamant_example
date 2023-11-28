#!/bin/sh

home="/home/user"
# First do a copy from /share to /home/user:
safe_copy() {
  src=$1
  dest=$2
  if [ ! -d "dest" ]; then
    echo "Copying $src to $dest..."
    cp -rf $src $dest
    echo "Done."
  else
    echo "Already copied $src to $dest."
  fi
}

echo "Copying shared repositories to /home/user to optimize build speed."
safe_copy /share/adamant $home/adamant
safe_copy /share/adamant_example $home/adamant_example

# Start unison:
echo "Starting Unison."
/share/adamant_example/docker/env/start_unison.sh &

# Set up alire:
echo "Setting up Alire build dependencies."
export PATH=$PATH:/home/user/env/bin
cd /home/user/adamant
alr -n build --release
alr -n toolchain --select gnat_native
alr -n toolchain --select gprbuild
cd /home/user/adamant_example
alr -n build --release
echo "Done."
