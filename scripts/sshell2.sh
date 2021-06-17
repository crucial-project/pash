#!/usr/bin/env bash

input=($@)

sendcmd1="nc -N -l 8080"
sendcmd2="rdv"
recvcmd1="exec 3<>/dev/tcp/"
recvcmd2="echo EOF >&3"

patternskip1="rm_pash_fifos"
patternskip2="mkfifo_pash_fifos()"
patternskip3="rm -f"
patternskip4="mkfifo"
patternskip5="/pash/runtime/eager.sh"
patternskip6="/pash/runtime/auto-split.sh"
patternskip7="source"

rm -f keyCmds.out
touch keyCmds.out

while read line
do

    if echo "$line" | grep -q "$patternskip1" || echo "$line" | grep -q "$patternskip3" || echo "$line" | grep -q "$patternskip4" || echo $line | grep -q "$patternskip5" || echo $line | grep -q "$patternskip6" || echo $line | grep -q "$patternskip7"; then
        continue
    fi	

    line=$(echo $line | sed 's/{//g')
    line=$(echo $line | sed 's/}//g')
    #line=$(echo $line | sed 's/&//g')
    line=$(echo $line | sed 's/;//g')
    line=$(echo $line | sed 's/</< /g')
    line=$(echo $line | sed 's/>/> /g')


    for index in "${!arrayline[@]}"
    do
		flagCmd=1
		#echo index arrayline: $index
		if [ $index == 0 ]
		then
			echo index arrayline 0
			echo arrayline: ${arrayline[$index]}
			itercmd=0
			cmd=""
			while [[ ${arrayline[$itercmd]} != "<" && ${arrayline[$itercmd]} != *"/tmp"* ]]
			do
				cmd="$cmd ${arrayline[$itercmd]}"
				itercmd=$((itercmd+1))
				echo itercmd: $itercmd
			done
			echo cmd: $cmd
			echo $cmd >> keyCmds.out
			keyCmdStore+="${arrayline[index]} "
			keyCmdStore+="${arrayline[index+1]}"
			keyCmdStore+=" "
		fi
    done

done < $input