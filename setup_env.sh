
#!/bin/bash

if [[ "$(uname)" == "Darwin" ]]; then
	brew update
	brew install zeromq --with-libsodium --HEAD
else
	sudo apt-get update
	sudo apt-get install build-essential pkg-config
	cd /
	sudo curl -O http://download.zeromq.org/zeromq-4.1.4.tar.gz
	sudo tar xf /zeromq-4.1.4.tar.gz
	cd /zeromq-4.1.4
	sudo ./configure --without-libsodium
	sudo make
	sudo make install
fi