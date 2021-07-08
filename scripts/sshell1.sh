#!/usr/bin/env bash

input=($@)
root="/"

sshcmd="ssh -t b313-11 '"
output=""
output2="#!/usr/bin/env bash"
routput=""
NEWLINE='\n'

output2="${output2} ${NEWLINE}"
output2="${output2} ${NEWLINE}"

pattern1="cat"
pattern2="head"
pattern3="rm"
pattern4="mkfifo"

patternskip1="/pash/runtime/eager.sh"
patternskip2="/pash/runtime/auto-split.sh"
patternskip3="source"

flagCmd="false"
flagPattern="false"
flagMatch=false
flagSSH="false"
flagSSHEnd="true"
condSSHEnd="false"
lastCmd=""
arrayCmdFirst=""

# Check if given string matches any command
matchCmd()
{
  	strl="$@"
	#arrayCmd="$2"
 
	echo matchCMD - line arg: "$@"
        echo matchCMD - line: $strl	
	#IFS=', ' read -r -a arraylinecmd <<< "$strl"

	for indexCmd in ${!arrayCmdFirst[@]}
	do
		echo ARRAY CMD ITEM: ${arrayCmdFirst[$indexCmd]}
		if echo "$strl" | grep -q "${arrayCmdFirst[$indexCmd]}"
		then
			echo SET FLAG CMD TO TRUE
			flagCmd="true"
			return 0
		fi
	done

	echo SET FLAG CMD TO FALSE
	flagCmd="false"
}

matchPattern()
{
	strl=$1 

	if  echo "$line" | grep -wq "$pattern1"  ||  echo "$line" | grep -wq "$pattern2"  ||  echo "$line" | grep -wq "$pattern3"  ||  echo "$line" | grep -wq "$pattern4"  
	then
		flagPattern="true"
	fi
}

rm -f keyCmds.out
touch keyCmds.out

# 1st step: extract commands
while read line 
do
	if echo "$line" | grep -q "$patternskip1" || echo "$line" | grep -q "$patternskip2" || echo "$line" | grep -q "$patternskip3"
	then
      		continue
        fi

	#line=$(echo $line | sed 's/</< /g')
    	#line=$(echo $line | sed 's/>/> /g')
	
	if echo "$line" | grep -q "$pattern1" || echo "$line" | grep -q "$pattern2"
	then
		flagCmd=true
	fi

	IFS=', ' read -r -a arrayline <<< "$line"
       
        for index in "${!arrayline[@]}"
        do
  		if [ "$flagCmd" = true ]
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

echo cat KeyCmds file :
cat keyCmds.out

echo ""
echo ""
arrayCmds=""
nbStages=""
itercmd=0

while read -r linecmd
do
	linecmd=$(echo $linecmd | sed "s/\"/'/g")

	IFS=', ' read -r -a arraylinecmd <<< "$linecmd"

	echo iter key: $itercmd
	echo lineKey: $linecmd

	arrayCmds[$itercmd]=$linecmd
	arrayCmdFirst[$itercmd]=${arraylinecmd[0]}
	echo Cmd First: ${arrayCmdFirst[$itercmd]}
	#keyCmds[$iterKeys]=$linekey						
	itercmd=$((itercmd+1))
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
		echo ""	
	fi

done < routputtmp.out

# prefix lines with sshell / ssh
while read line
do
	flagCmd="false"
	flagPattern="false"
	flagSSH="false"

	#line=$(echo $line | sed "s/mkfifo \"/mkfifo /g")
	#line=$(echo $line | sed "s/rm -f \"/rm -f /g")
	#line=$(echo $line | sed "s/\" ;/ ;/g")
	#line=$(echo $line | sed "s/\" &/ &/g")
	#line=$(echo $line | sed "s/<\"/< /g")
	#line=$(echo $line | sed "s/>\"/> /g")

	IFS=', ' read -r -a arrayline <<< "$line"

	matchCmd $line 
	#matchPattern $line

	#if  echo "$flagPattern" | grep -q "true"  
	if  echo "$line" | grep -wq "$pattern1"  ||  echo "$line" | grep -wq "$pattern2"  ||  echo "$line" | grep -wq "$pattern3"  ||  echo "$line" | grep -wq "$pattern4" || echo "$line" | grep -wq "$patternskip1" || echo "$line" | grep -wq "$patternskip2" || echo "$flagCmd" | grep 'true' 
	then
		echo LINE TRUE
		flagSSHEnd="true"

		for index in "${!arrayline[@]}"
		do
			flagCmd="false"
			flagPattern="false"
	
			matchCmd ${arrayline[$index]} 
			#matchPattern ${arrayline[$index]}
			echo flagCmd: $flagCmd
			#if echo "$flagPattern" | grep -q "true" 
			if  echo "${arrayline[$index]}" | grep -wq "$pattern1"  ||  echo "${arrayline[$index]}" | grep -wq "$pattern2"  ||  echo "${arrayline[$index]}" | grep -wq "$pattern3"  ||  echo "${arrayline[$index]}" | grep -wq "$pattern4" || echo "${arrayline[$index]}" | grep -wq "$patternskip1" || echo "${arrayline[$index]}" | grep -wq "$patternskip2" || echo "${arrayline[$index]}" | grep -wq "$patternskip3" || echo "$flagCmd" | grep 'true' 
			then
				#echo PATTERN HIT : ${arrayline[$index]}
				output2="${output2} ${sshcmd} ${arrayline[$index]}" 
				#output2="${output2} ${arrayline[$index]}" 
				flagSSH="true"

				#if echo "${arrayline[$index]}" | grep '}' || echo "${arrayline[$index]}" | grep '&'
				#then
				#	output2="${output2} AHAH ${arrayline[$index]}"
				#fi

			else
				echo MISS
				output2="${output2} ${arrayline[$index]}" 
			fi

			if echo "${arrayline[$index]}" | grep '}' || echo "${arrayline[$index]}" | grep '&'
			then
				condSSHEnd="true"
			fi

			if echo "$condSSHEnd" | grep 'true' && echo "$flagSSH" | grep 'true' && echo "$flagSSHEnd" | grep 'true'
			then
				#output2="${output2} AHAH ${arrayline[$index]}"
				flagSSHEnd="false"
				#break
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
echo -e $output2 > /tmp/sshell1_pash_unix50_2.sh 
