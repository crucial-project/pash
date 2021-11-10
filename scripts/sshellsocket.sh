#!/usr/bin/env bash

input=($@)

PORT=12345
IP=127.0.0.1
getIP="\\\\\$(hostname -I | awk '{ print \\\\\$1 }')"
#mailbox=$(uuid)

root="/netfs/inf/amaheo"
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
NEWTRAIL2='\t\t\t'
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

endcmd="awk '{print \\\\\$0}END{print \\\"EOF\\\"}'"
killcmd="&& kill \\\\\$\\\\\$"
recvfile1="tail -n +0 -f --pid=\\\\\$\\\\\$ --retry"
recvfile2="2>/dev/null | { sed /EOF/ q ;} | grep -v ^EOF\\\\\$"


funcrdv=""
funcrdv="${funcrdv} rdv()"
funcrdv="${funcrdv} ${NEWLINE}"
funcrdv="${funcrdv} {"
funcrdv="${funcrdv} ${NEWLINE}"
funcrdv="${funcrdv} ${NEWTRAIL} file=\$1"
funcrdv="${funcrdv} ${NEWLINE}"
funcrdv="${funcrdv} ${NEWTRAIL} IP=\$3"
funcrdv="${funcrdv} ${NEWLINE}"
funcrdv="${funcrdv} ${NEWTRAIL} if [ \$# -eq 1 ]"
funcrdv="${funcrdv} ${NEWLINE}"
funcrdv="${funcrdv} ${NEWTRAIL}  then"
funcrdv="${funcrdv} ${NEWLINE}"
funcrdv="${funcrdv} ${NEWTRAIL1} while [ ! -f \$1 ]"
funcrdv="${funcrdv} ${NEWLINE}"
funcrdv="${funcrdv} ${NEWTRAIL1} do"
funcrdv="${funcrdv} ${NEWLINE}"
funcrdv="${funcrdv} ${NEWTRAIL2} sleep 1"
funcrdv="${funcrdv} ${NEWLINE}"
funcrdv="${funcrdv} ${NEWTRAIL1} done"
funcrdv="${funcrdv} ${NEWLINE}"
funcrdv="${funcrdv} ${NEWTRAIL1} IP=\$(cat \$1)"
funcrdv="${funcrdv} ${NEWLINE}"
funcrdv="${funcrdv} ${NEWTRAIL1} echo \$IP"
funcrdv="${funcrdv} ${NEWLINE}"
funcrdv="${funcrdv} ${NEWTRAIL} elif [ \$# -eq 3 ]"
funcrdv="${funcrdv} ${NEWLINE}"
funcrdv="${funcrdv} ${NEWTRAIL} then"
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

output="#!/usr/bin/env bash"
output="${output} ${NEWLINE}"
output="${output} ${NEWLINE}"
output="${output} ${funcrdv}"
output="${output} ${NEWLINE}"
output="${output} ${NEWLINE}"

echo -e $output > ${root}/sshellsocket1.tmp

while read line
do

	line=$(echo $line | sed 's/\<mkfifo\>/touch/g')
	line=$(echo $line | sed 's/#fifo/fifo/g')
	line=$(echo $line | sed 's/"\/tmp/ \/tmp/g')
	line=$(echo $line | sed "s|/tmp|${root}/tmp|g")
	#line=$(echo $line | sed 's/fifo\[0-9]"/fifo\[0-9]/g')
	#line=$(echo $line | sed 's/" ;/ ;/g')
	#line=$(echo $line | sed 's/" >/ >/g')
	#line=$(echo $line | sed 's/"//g')
	line=$(echo $line | sed 's/\("\s"\)\|"/\1/g')
	#line=$(echo $line | sed 's/" &/  &/g')

	if echo "$line" | grep -q "$patterneager"
	then
		#echo eager pattern detected
	        IFS=', ' read -r -a arrayline <<< "$line"

		#echo ${arrayline[1]}
		#echo ${arrayline[2]}
		#echo ${arrayline[3]}
                #output="${output} { cp ${arrayline[2]} ${arrayline[3]} & }"
                #echo "{ rsync --partial ${arrayline[2]} ${arrayline[3]} & }"
		#output="${output} { ${recvfile1} ${arrayline[2]} ${recvfile2} | ${endcmd} > ${arrayline[3]} ${killcmd} \" & }"
		echo "{ ${recvfile1} ${arrayline[2]} ${recvfile2} | ${endcmd} > ${arrayline[3]} ${killcmd} \" & }"
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

done < $input > ${root}/sshellsocket2.tmp 

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

	#mailbox=$(uuid)
	mailbox=${root}/tmp/$(date +%s%N)

	#recvcmd="IP=${getIP}; rdv ${mailbox} -1 \\\\\$IP ; nc -N -l ${PORT}"
	recvcmd="IP=${getIP}; rdv ${mailbox} -1 \\\\\$IP ; nc \\\\\$IP ${PORT}"
	#recvcmd2="rdv ${mailbox} -1 \\\\\$IP"

	#sendcmd1="HOST=\\\\\$(rdv ${mailbox}); exec 3<>/dev/tcp/\\\\\${HOST}/${PORT};"
	#sendcmd2="echo EOF >&3 && kill \\\\\$\\\\\$"
	sendcmd="HOST=\\\\\$(rdv ${mailbox}); nc -l ${PORT} < source.in"

	if echo "$line" | grep -q "$pattern2" && echo "$line" | grep -q "$pattern3" 
	then
		line=$(echo $line | sed 's/{//g')
		line=$(echo $line | sed 's/}//g')
		line=$(echo $line | sed 's/&//g')

	        IFS=$pattern2 read -r -a arrayline1 <<< "$line"

		cmd1=${arrayline1[0]}
		cmd1=$(echo $cmd1 | sed 's/" "/\\\\\" \\\\\"/g')
		#echo cmd1 : $cmd1
		#echo arrayline1 : ${arrayline1[1]}
	        IFS=$pattern3 read -r -a arrayline2 <<< "${arrayline1[1]}"

		cmd2="tail -n +0 --retry -f --pid=\\\\\$\\\\\$ ${arrayline2[0]} | { sed \\\\\"/EOF/ q\\\\\" ;} | grep -v ^EOF\\\\\$ > source.in "
		#echo cmd2 : $cmd2

		echo "{ ${recvcmd} | ${cmd1} > ${arrayline2[1]} & }"
		#echo "{ ${recvcmd} | ${cmd1}& & }"
		#echo "{ ${sendcmd} ${cmd2} >&3; ${sendcmd2} & }"
		echo "{ ${cmd2} ; ${sendcmd} & }"
	else
		echo "${line}"
	fi

done < ${root}/sshellsocket2.tmp > ${root}/sshellsocket3.tmp

echo THIRD STEP

csplit -z -f 'tempPASH' -b '%0d.txt' ${root}/sshellsocket3.tmp /mkfifo_pash_fifos/ {*}

while read line
do
	RANDOM=$(date +%s%N)
	sshmachine=${arrssh[$RANDOM % ${#arrssh[@]} ]}

	line=$(echo "$line" | sed -r "s/^[{]/{ nohup ssh -tt amaheo@$sshmachine \" \$(declare -f rdv);/g")
	line=$(echo "$line" | sed -r "s/& }/\" &/g")
	echo $line

done < tempPASH2.txt > outfile

inputfile=$(basename $input)

#touch pipesshellsocket.sh
cat ${root}/sshellsocket1.tmp > sshellbackendsocket_$inputfile
#echo "" >> pipesshellsocket.sh
cat tempPASH0.txt >> sshellbackendsocket_$inputfile
cat tempPASH1.txt >> sshellbackendsocket_$inputfile
cat outfile >> sshellbackendsocket_$inputfile

echo OUTPUT
echo ==================
#echo -e $output 
