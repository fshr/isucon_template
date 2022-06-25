#!/usr/bin/bash

cd /home/isucon/webapp/go/

make all

sudo systemctl restart isucholar.go
