
#!/bin/bash

if [[ "$(uname)" == "Darwin" ]]; then
	brew update
	brew install zeromq --with-libsodium
else
	sudo apt-get update
	sudo apt-get install libzmq-4-dev
fi