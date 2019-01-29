#!/bin/bash

singularity_version="${singularity_version:-3.0.2}"
GO_VERSION=1.11.5

sudo apt-get update && \
     sudo apt-get install -y wget \
                             git \
                             build-essential \
                             squashfs-tools \
                             libtool \
                             uuid-dev \
                             libssl-dev \
                             libgpgme11-dev \
                             libseccomp-dev \
                             pkg-config


sudo sed -i -e 's/^Defaults\tsecure_path.*$//' /etc/sudoers

# Check Python

echo "Python Version:"
python --version
pip install sregistry[all]
sregistry_version=$(sregistry version)
echo "sregistry Version: ${sregistry_version}"

# Install GoLang

ls
if [ ! -f "go/api/README" ]
    then
        wget https://dl.google.com/go/go${GO_VERSION}.src.tar.gz && \
        tar -C /usr/local -xzf go${GO_VERSION}.src.tar.gz
fi

export PATH=$PATH:/usr/local/go/bin && \
    sudo mkdir -p /go && \
    sudo chmod -R 7777 /go

# Install Singularity

export GOPATH=/go && \
    go get -u github.com/golang/dep/cmd/dep && \
    mkdir -p ${GOPATH}/src/github.com/sylabs && \
    cd ${GOPATH}/src/github.com/sylabs && \
    wget https://github.com/sylabs/singularity/releases/download/v${singularity_version}/singularity-${singularity_version}.tar.gz && \
    tar -xzvf singularity-${singularity_version}.tar.gz && \
    cd singularity && \
    ./mconfig -p /usr/local && \
    make -C builddir && \
    sudo make -C builddir install
