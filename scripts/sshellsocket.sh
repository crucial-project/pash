#!/usr/bin/env bash

input=($@)

PORT=8080
IP=127.0.0.1
#mailbox=$(uuid)

root="/home/aurele/tmp"
#HOST=$(rdv ${pipe})

if [ $# -eq 0 ]
  then
    echo "Usage: $> bash sshellsocket <script>"
    exit
fi

arrssh=()
while IFS= read -r line; do
  arrssh+=("$line")
done < configssh.txt

NEWLINE='\n'
NEWTRAIL='\t'
NEWTRAIL1='\t\t'
cmd1=""
cmd2=""

#pattern1="rm_pash_fifos"
#pattern2="mkfifo_pash_fifos()"
#pattern3="rm -f"
pattern1="mkfifo"
pattern2="<"
pattern3=">"
patterneager="/pash/runtime/eager.sh"
#pattern6="/pash/runtime/auto-split.sh"
#pattern7="source"


funcrdv=""
funcrdv="${funcrdv} rdv()"
funcrdv="${funcrdv} ${NEWLINE}"
funcrdv="${funcrdv} {"
funcrdv="${funcrdv} ${NEWLINE}"
funcrdv="${funcrdv} ${NEWTRAIL} file=\$1"
funcrdv="${funcrdv} ${NEWLINE}"
funcrdv="${funcrdv} ${NEWTRAIL} IP=\$3"
funcrdv="${funcrdv} ${NEWLINE}"
funcrdv="${funcrdv} ${NEWTRAIL} if $# -eq 1"
funcrdv="${funcrdv} ${NEWLINE}"
funcrdv="${funcrdv} ${NEWTRAIL}  then"
funcrdv="${funcrdv} ${NEWLINE}"
funcrdv="${funcrdv} ${NEWTRAIL1} echo reader"
funcrdv="${funcrdv} ${NEWLINE}"
funcrdv="${funcrdv} ${NEWTRAIL1} IP=\$(cat \$1)"
funcrdv="${funcrdv} ${NEWLINE}"
funcrdv="${funcrdv} ${NEWTRAIL1} return \$IP"
funcrdv="${funcrdv} ${NEWLINE}"
funcrdv="${funcrdv} ${NEWTRAIL} elif \$# -eq 3"
funcrdv="${funcrdv} ${NEWLINE}"
funcrdv="${funcrdv} ${NEWTRAIL} then"
funcrdv="${funcrdv} ${NEWLINE}"
funcrdv="${funcrdv} ${NEWTRAIL1} echo writer"
funcrdv="${funcrdv} ${NEWLINE}"
funcrdv="${funcrdv} ${NEWTRAIL1} echo \$3 > \$1"
funcrdv="${funcrdv} ${NEWLINE}"
funcrdv="${funcrdv} ${NEWTRAIL1} return 0"
funcrdv="${funcrdv} ${NEWLINE}"
funcrdv="${funcrdv} ${NEWTRAIL} else"
funcrdv="${funcrdv} ${NEWLINE}"
funcrdv="${funcrdv} ${NEWTRAIL1} echo \"Usage: rdv <file> or rdv <file> -1 <IP>\"":
funcrdv="${funcrdv} ${NEWLINE}"
funcrdv="${funcrdv} ${NEWTRAIL} fi"
funcrdv="${funcrdv} ${NEWLINE}"
funcrdv="${funcrdv} }"
funcrdv="${funcrdv} ${NEWLINE}"
funcrdv="${funcrdv} ${NEWLINE}"
funcrdv="${funcrdv} ${NEWLINE}"

output="#!/usr/bin/env bash"
output="${output} ${NEWLINE}"
output="${output} ${NEWLINE}"
output="${output} ${funcrdv}"
output="${output} ${NEWLINE}"
output="${output} ${NEWLINE}"

while read line
do

	line=$(echo $line | sed 's/\<mkfifo\>/touch/g')
	line=$(echo $line | sed 's/#fifo/fifo/g')
	line=$(echo $line | sed 's/"\/tmp/ \/tmp/g')
	line=$(echo $line | sed 's/" ;/ ;/g')
	line=$(echo $line | sed 's/" >/ >/g')
	#line=$(echo $line | sed 's/" &/  &/g')

	if echo "$line" | grep -q "$patterneager"
	then
		#echo eager pattern detected
	        IFS=', ' read -r -a arrayline <<< "$line"

		#echo ${arrayline[1]}
		#echo ${arrayline[2]}
		#echo ${arrayline[3]}
                #output="${output} { cp ${arrayline[2]} ${arrayline[3]} & }"
                echo "{ cp ${arrayline[2]} ${arrayline[3]} & }"
		#output="${output} ${NEWLINE}"
	else
		echo $line
		#output="${output} ${line}"
		#output="${output} ${NEWLINE}"
	fi

	# Collect and store commands from the input script
  	for index in "${!arrayline[@]}"
    	do
		flagCmd=1
		#echo index arrayline: $index
		if [ $index == 0 ]
		then
			#echo index arrayline 0
			#echo arrayline: ${arrayline[$index]}
			itercmd=0
			cmd=""
			while [[ ${arrayline[$itercmd]} != "<" && ${arrayline[$itercmd]} != *"/tmp"* ]]
			do
				cmd="$cmd ${arrayline[$itercmd]}"
				itercmd=$((itercmd+1))
				#echo itercmd: $itercmd
			done
			#echo cmd: $cmd
			#echo $cmd >> keyCmds.out
			keyCmdStore+="${arrayline[index]} "
			keyCmdStore+="${arrayline[index+1]}"
			keyCmdStore+=" "
		fi
    	done

done < $input > ${root}/sshellsocket.tmp 

echo keyCmds file:
cat keyCmds.out
echo keyCmds file uniq:
cat keyCmds.out | uniq > keyCmdsUniq.out
echo keyCmdsUniq.out : 
cat keyCmdsUniq.out

while read -r linecmd
do
	itercmd=$((itercmd+1))
	linecmd=$(echo $linecmd | sed "s/\"/'/g")
	echo iter key: $itercmd

	echo lineKey: $linecmd

	arrayCmds[$itercmd]=$linecmd
	#keyCmds[$iterKeys]=$linekey						
done < keyCmdsUniq.out

echo SECOND STEP

while read line
do

	mailbox=$(uuid)
	recvcmd1="nc -N -l ${PORT}"
	recvcmd2="rdv ${mailbox} -1 \$IP"

	sendcmd1="HOST=\$(rdv ${mailbox}); exec 3<>/dev/tcp/\$(HOST)/\$(PORT);"
	sendcmd2="echo EOF >&3"

	if echo "$line" | grep -q "$pattern2" && echo "$line" | grep -q "$pattern3" 
	then
		line=$(echo $line | sed 's/{//g')
		line=$(echo $line | sed 's/}//g')

	        IFS=$pattern2 read -r -a arrayline1 <<< "$line"

		cmd1=${arrayline1[0]}
		echo cmd1 : $cmd1
		echo arrayline1 : ${arrayline1[1]}
	        IFS=$pattern3 read -r -a arrayline2 <<< "${arrayline1[1]}"

		cmd2="cat ${arrayline2[0]}"
		echo cmd2 : $cmd2

		output="${output} ${recvcmd1} | ${cmd1}& ${recvcmd2}"
		output="${output} ${NEWLINE}"
		output="${output} ${sendcmd1} ${cmd2} >&3; ${sendcmd2}"
		output="${output} ${NEWLINE}"
	else

		output="${output} ${line}"
		output="${output} ${NEWLINE}"
	fi

done < ${root}/sshellsocket.tmp

echo THIRD STEP

#while read line
#do
#	echo $line

#done < ${root}/sshellsocket.tmp

echo OUTPUT
echo ==================
echo -e $output 
