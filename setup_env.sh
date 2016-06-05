
#!/bin/bash

if [[ "$(uname)" == "Linux" ]]; then
	sudo apt-get update
	sudo apt-get install build-essential pkg-config
fi

cd /tmp/
sudo curl -O https://github.com/zeromq/zeromq4-1/releases/download/v4.1.4/zeromq-4.1.4.tar.gz
sudo tar xf /tmp/zeromq-4.1.4.tar.gz
cd /tmp/zeromq-4.1.4
sudo ./configure --without-libsodium
sudo make
sudo make install
