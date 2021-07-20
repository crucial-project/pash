#!/usr/bin/env bash

input=($@)

PAR=2

arrssh=()
while IFS= read -r line; do
  arrssh+=("$line")
done < configssh.txt

echo ARRAY SSH MACHINES
lenArraySSH=${#arrssh[@]}

RANDOM=$$$(date +%s)

sshmachine=${arrssh[$RANDOM % ${#arrssh[@]} ]}

echo Random machine : $sshmachine

echo $lenArraySSH

csplit -z -f 'tempPASH' -b '%0d.txt' $input /mkfifo_pash_fifos/ {*}

sed -i "s/{ /{ ssh -tt $sshmachine '/g" tempPASH2.txt 

sed -i "s/&/' &/g" tempPASH2.txt 

cat tempPASH0.txt > ssh_pash.sh
cat tempPASH1.txt >> ssh_pash.sh
cat tempPASH2.txt >> ssh_pash.sh

