#!/usr/bin/env bash

input=($@)

PAR=2

arrssh=()
while IFS= read -r line; do
  arrssh+=("$line")
done < configssh.txt

echo ARRAY SSH MACHINES
lenArraySSH=${#arrssh[@]}

#$RANDOM=$$$(date +%s)

#sshmachine=${arrssh[$RANDOM % ${#arrssh[@]} ]}

#echo Random machine : $sshmachine

echo $lenArraySSH

csplit -z -f 'tempPASH' -b '%0d.txt' $input /mkfifo_pash_fifos/ {*}

#rndm=($(shuf -e {00..12}))

while read line
do
	RANDOM=$(date +%s%N)
	sshmachine=${arrssh[$RANDOM % ${#arrssh[@]} ]}

	line=$(echo "$line" | sed -r "s/^[{]/{ssh -tt amaheo@$sshmachine '/g")
        echo $line | sed -r "s/&/' &/g"	

done < tempPASH2.txt > outfile

#sed -i "s/{ /{ ssh -tt amaheo@$RANDOM '/g" tempPASH2.txt 
#sed -i "s/{ /{ ssh -tt amaheo@${arrssh[$$$(date +%s%N) % ${#arrssh[@]}]} '/g" tempPASH2.txt 

sed -i "s/&/' &/g" tempPASH2.txt 

cat tempPASH0.txt > ssh_pash.sh
cat tempPASH1.txt >> ssh_pash.sh
cat outfile >> ssh_pash.sh
#cat tempPASH2.txt >> ssh_pash.sh

sed -i "s/\/tmp/\/netfs\/inf\/amaheo\/tmp/g" ssh_pash.sh
