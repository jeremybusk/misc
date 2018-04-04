#!/usr/bin/env bash
## Set BASH environment so it will fail properly throwing exit code
#set -euxo pipefail
set -v

# Get RChain Repo
apt update
apt -y install git
git clone https://github.com/rchain/rchain
cd rchain
project_root_dir=$(pwd)
git checkout dev
### Install all dependencies on Ubuntu 16.04 LTS (Xenial Xerus) for RChain dev environment
## Detect if running in docker container - setup using sudo accordingly
if [[ $(cat /proc/self/cgroup  | grep docker) = *docker* ]]; then
    echo "Running in docker container!"
    sudo=""
else
    sudo="sudo"
fi
## Verify operating system (OS) version is Ubuntu 16.04 LTS (Xenial Xerus)
# Add more OS versions as necessary. 
version=$(cat /etc/*release | grep "^VERSION_ID" | awk -F= '{print $2}' | sed 's/"//g')
if [[ "$version" == "16.04" ]]; then
    echo "Running install on Ubuntu 16.04" 
else
    echo "Error: Not running on Ubuntu 16.04"
    echo "Exiting"
    exit
fi
## Resynchronize the package index files from their sources
apt-get update -yqq
## Install g++ multilib for cross-compiling as rosette is currently only 32-bit 
apt-get install g++-multilib -yqq
## Install misc tools 
apt-get install cmake curl git -yqq
## Install Java OpenJDK 8
apt-get update -yqq
#  apt-get install default-jdk -yqq # alternate jdk install 
apt-get install openjdk-8-jdk -yqq
## Build needed crypto
apt-get install autoconf libtool -yqq
cd crypto
if [ -d "secp256k1" ]; then
    rm -rf secp256k1 
fi
git clone https://github.com/bitcoin-core/secp256k1
cd secp256k1
./autogen.sh
./configure --enable-jni --enable-experimental --enable-module-schnorr --enable-module-ecdh --prefix=/tmp/f/rchain/.tmp
make
cd 
## Build libsodium
cd crypto
if [ -d "libsodium" ]; then
    rm -rf libsodium 
fi
git clone https://github.com/jedisct1/libsodium --branch stable
cd libsodium
./configure
make && make check
make install
## Install Haskell Platform
# ref: https://www.haskell.org/platform/#linux-ubuntu
# ref: https://www.haskell.org/platform/ # all platforms
apt-get install haskell-platform -yqq
## Install BNFC Converter 
# ref: http://bnfc.digitalgrammars.com/
bnfc_tmp_dir="/tmp/bnfcbuild.b3PylB"
cd 
git clone https://github.com/BNFC/bnfc.git
cd bnfc/source
cabal install --global
cd 
## Install sbt
apt-get install apt-transport-https -yqq
echo "deb https://dl.bintray.com/sbt/debian /" |  tee -a /etc/apt/sources.list.d/sbt.list
apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 2EE0EA64E40A89B84B2DF73499E82A75642AC823
apt-get update -yqq
apt-get install sbt -yqq
## Install JFlex 
apt-get install jflex -yqq
## Remove temporary files 
rm -rf 
# Install Docker-CE
apt-get install -y apt-transport-https ca-certificates curl software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg |  apt-key add -
add-apt-repository    "deb [arch=amd64] https://download.docker.com/linux/ubuntu    xenial    stable"
apt update
apt install -y docker-ce
# Install and Build RChain
cd ${project_root_dir}
sbt rholang/bnfc:generate
sbt rholang/compile
sbt rholang/assembly
sbt rspace/compile
sbt rspace/assembly
sbt node/compile
sbt node/assembly
sbt node/docker

## Tag and push newly built docker image(s).
# Setup auth, source image(s) and target/destination image(s) name in variables 
docker_user="youuser"
docker_pass="yourpass"
docker_src_repo="mylocal/node"
docker_src_tag="latest"
docker_dst_repo="jeremybusk/node"
docker_dst_tag="jtest"
docker tag  ${docker_src_repo}:${docker_src_tag} ${docker_dst_repo}:${docker_dst_tag}
docker login -u "${docker_user}" -p "${docker_pass}"
docker push ${docker_dst_repo}:${docker_dst_tag}

echo """Login to docker hub manually and push docker image 
docker login -u <username>
<enter pass>
docker push ${docker_dst_repo}:<your specific tag>
"""
