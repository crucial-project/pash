#!/usr/bin/env bash

input=($@)

csplit -z -f 'tempPASH' -b '%0d.txt' $input /mkfifo_pash_fifos/ {*}

sed -i "s/{/{ ssh -t localhost '/g" tempPASH2.txt 

sed -i "s/&/' &/g" tempPASH2.txt 

cat tempPASH0.txt > res.out 
cat tempPASH1.txt >> res.out 
cat tempPASH2.txt >> res.out 

