
#!/bin/bash

if [ "$(uname)" == "Darwin" ]; then
	brew update
	brew install zeromq --with-libsodium
else
	apt-get update
	apt-get install libzmq-4-dev
fi