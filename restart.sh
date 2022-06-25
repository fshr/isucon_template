#!/usr/bin/bash

cd /home/isucon/webapp/go/

make all

systemctl restart isucholar.go
