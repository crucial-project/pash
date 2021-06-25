#!/usr/bin/env bash

input=($@)

PORT=8080
IP=127.0.0.1
pipe=$(uuid)
HOST=$(rdv ${pipe})

sendcmd1="nc -N -l ${PORT}"
sendcmd2="rdv"
sendcmd3="-1 ${IP}"
recvcmd1="exec 3<>/dev/tcp/${HOST}/${PORT}"
recvcmd2="&3"
recvcmd3="echo EOF >&3"

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

    # Collect and store commands from the input script
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

echo keyCmds file:
cat keyCmds.out
echo keyCmds file uniq:
cat keyCmds.out | uniq > keyCmdsUniq.out
echo keyCmdsUniq.out : 
cat keyCmdsUniq.out
itercmd=0
inputCmds=keyCmdsUniq.out
arrayCmds=""

while read -r linecmd
do
	itercmd=$((itercmd+1))
	linecmd=$(echo $linecmd | sed "s/\"/'/g")
	echo iter key: $itercmd

	echo lineKey: $linecmd

	arrayCmds[$itercmd]=$linecmd
	#keyCmds[$iterKeys]=$linekey						
done < keyCmdsUniq.out

nbstages=$(cat keyCmdsUniq.out | wc -l)
nbstagesmone=$((nbstages - 1))
echo Number of stages in pipeline: $nbstages

# Build output script based on collected commands
for itercmd in $(seq 1 $nbstages)
do
 	echo arrayCmds $itercmd: ${arrayCmds[$itercmd]}
	if [ $itercmd == $nbstages ]
	then	
		fileparoutput=""
		output="${output} ${NEWLINE}"
		output="${output} ${NEWLINE}"

		for iterpar in $(seq 1 $PAR)
		do
			cmd=${arrayCmds[$itercmd]}
			output="${output} ${sshell} \"${recvcmd} "${arrayPipes[$iterpar]}" > ${root}/par_$iterpar.out\""
			output="${output} ${NEWLINE}"
			fileparoutput+=" ${root}/par_$iterpar.out"
		done

		output="${output} ${NEWLINE}"
		output="${output} ${NEWLINE}"
        output="${output} ${sshell} \"sort -m ${fileparoutput} > ${root}/res.out\""
		output="${output} ${NEWLINE}"

	else
		cmd=${arrayCmds[$itercmd]}

		for iterpar in $(seq 1 $PAR)
		do
			arrayPipesNext[$iterpar]="${root}/$(uuid)"
			output="${output} ${sshell} \" ${recvcmd} ${arrayPipes[$iterpar]} | ${cmd} > ${arrayPipesNext[$iterpar]} \""
			output="${output} ${NEWLINE}"
			arrayPipes[$iterpar]=${arrayPipesNext[$iterpar]}

		done
		output="${output} ${NEWLINE}"
		output="${output} ${NEWLINE}"
	fi 
done

echo OUTPUT
echo ==================
echo -e $output > pipessshellsockets.sh 

