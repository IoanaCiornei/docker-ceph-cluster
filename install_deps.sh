#! /bin/bash

while read pkg; do
	sudo apt-get install -y $pkg
done < deps
