#!/usr/bin/env bash

input=($@)
root="/"

output=""
output2=""
routput=""
NEWLINE='\n'

pattern1="cat"
pattern2="head"

flagCmd=0
lasCmd=""

rm -f keyCmds.out
touch keyCmds.out

while read line 
do

	line=$(echo $line | sed 's/</< /g')
    	line=$(echo $line | sed 's/>/> /g')
	
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
		echo HIT	
	fi

        #for index in "${!arrayline[@]}"
	#do
	#	echo "FOR"
	#done

done < routputtmp.out

echo OUTPUT
echo ==================
echo -e $output  
