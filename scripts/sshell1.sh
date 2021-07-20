#!/usr/bin/env bash

input=($@)

csplit -z -f 'tempPASH' -b '%0d.txt' $input /mkfifo_pash_fifos/ {*}

sed -i "s/{ /{ ssh -tt localhost '/g" tempPASH2.txt 

sed -i "s/&/' &/g" tempPASH2.txt 

cat tempPASH0.txt > ssh_pash.sh
cat tempPASH1.txt >> ssh_pash.sh
cat tempPASH2.txt >> ssh_pash.sh

