#!/usr/bin/env bash

input=($@)
root="/"

sshcmd="ssh -t b313-11"
output=""
output2=""
routput=""
NEWLINE='\n'

pattern1="cat"
pattern2="head"
pattern3="rm"
pattern4="mkfifo"

patternskip1="/pash/runtime/eager.sh"
patternskip2="/pash/runtime/auto-split.sh"
patternskip3="source"

flagCmd=0
lastCmd=""

rm -f keyCmds.out
touch keyCmds.out

# 1st step: extract commands
while read line 
do

	#if echo "$line" | grep -q "$patternskip1" || echo "$line" | grep -q "$patternskip2" || echo "$line" | grep -q "$patternskip3"
	#then
      	#	continue
        #fi

	#line=$(echo $line | sed 's/</< /g')
    	#line=$(echo $line | sed 's/>/> /g')
	
	if echo "$line" | grep -q "$pattern1" || echo "$line" | grep -q "$pattern2"
	then
		flagCmd=1
	fi

	IFS=', ' read -r -a arrayline <<< "$line"
       
        for index in "${!arrayline[@]}"
        do
  		if [ $flagCmd == 1 ]
		then
			if [[ $index == 0 && ${arrayline[0]} == "{" ]]
			then
				echo index arrayline 0
				echo arrayline: ${arrayline[$index]}
				itercmd=0
				cmd=""
			
				while [[ ${arrayline[$itercmd]} != "<" && ${arrayline[$itercmd]} != *"/tmp"* ]]
				do
					cmd="$cmd ${arrayline[$itercmd]}"
					cmd=$(echo $cmd | sed 's/{//g')
					itercmd=$((itercmd+1))
					echo itercmd: $itercmd
				done
				
				echo cmd: $cmd
				echo $cmd >> keyCmds.out
				#keyCmdStore+="${arrayline[index]} "
				#keyCmdStore+="${arrayline[index+1]}"
				#keyCmdStore+=" "
			fi
		fi
        done	       

	output="${output} ${line}"
	output="${output} ${NEWLINE}"

done < $input

echo -e $output > outputtmp.out
echo  last line: $lastCmdLine

echo OUTPUT 1
echo -e $output
echo ==================================

cat keyCmds.out

arrayCmds=""
nbStages=""

while read -r linecmd
do
	#itercmd=$((itercmd+1))
	linecmd=$(echo $linecmd | sed "s/\"/'/g")
	echo iter key: $itercmd

	echo lineKey: $linecmd

	arrayCmds[$itercmd]=$linecmd
	#keyCmds[$iterKeys]=$linekey						
done < keyCmds.out

nbStages=$(cat keyCmds.out | wc -l)

sizeoutputtmp=$(cat outputtmp.out | wc -l)
lastCmdLineNb=$((sizeoutputtmp - 2))
lastCmdLine=$(sed "$lastCmdLineNb!d" outputtmp.out)
nbOccFifos=0
iterrOutput=0

lastLineArrayFifos=""
arrayFifos=""

IFS=', ' read -r -a arrayline <<< "$lastCmdLine"

for index in "${!arrayline[@]}"
do
	if echo "${arrayline[$index]}" | grep -q "fifo"
	then
		lastLineArrayFifos[$nbOccFifos]=${arrayline[$index]}	
		nbOccFifos=$((nbOccFifos+1))
	fi
done

echo Last FIFO line :
echo Number of fifo occurrences: $nbOccFifos

for indexOcc in "${!lastLineArrayFifos[@]}"
do
	echo index $indexOcc
	echo array Occ : ${lastLineArrayFifos[$indexOcc]}	
done

while read -r line
do
	
	IFS=', ' read -r -a arrayline <<< "$line"

	if echo "${arrayline[1]}" | grep -q "${arrayCmds[nbStages-1]}"
	then
		echo KEY HIT	
	fi

done < routputtmp.out

# prefix lines with sshell / ssh
while read line
do
	IFS=', ' read -r -a arrayline <<< "$line"

	if echo "$line" | grep -wq "$pattern1" || echo "$line" | grep -wq "$pattern2" || echo "$line" | grep -wq "$pattern3" || echo "$line" | grep -wq "$pattern4"
	then
		for index in "${!arrayline[@]}"
		do
			if echo "${arrayline[$index]}" | grep -wq  "$pattern1" || echo "${arrayline[$index]}" | grep -wq "$pattern2" || echo "${arrayline[$index]}" | grep -wq "$pattern3" || echo "${arrayline[$index]}" | grep -wq "$pattern4" 
			then
				echo PATTERN HIT : ${arrayline[$index]}
				output2="${output2} ${sshcmd} ${arrayline[$index]}" 
			else
				echo MISS
				output2="${output2} ${arrayline[$index]}" 
			fi	
		done
	else
		for index in "${!arrayline[@]}"
		do
			output2="${output2} ${arrayline[$index]}" 
		done
	fi

	output2="${output2} ${NEWLINE}"
 
done < $input

echo OUTPUT 2
echo ==================
echo -e $output2  
