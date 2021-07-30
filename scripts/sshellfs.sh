#!/usr/bin/env bash

PAR=2

input=($@)

if [ $# -eq 0 ]
  then
    echo "No arguments supplied: abort"
    exit
fi

NEWLINE='\n'

sendcmd="awk '{print \\\$0}END{print \\\"EOF\\\"}'"
recvcmd1="tail -n +0 --pid=\\$\\$ --retry"
recvcmd2="2>/dev/null | { sed '/EOF/ q' && kill \$\$ ;} | grep -v ^EOF\\$"

output1="#!/usr/bin/env bash"
output1="${output1} ${NEWLINE}"
output1="${output1} ${NEWLINE}"

skippattern="/pash/runtime/eager.sh"

while read line
do
	#if echo "$line" | grep -q "$skippattern"
	#then
	#	continue
	#fi

	output1="${output1} ${line}"
	output1="${output1} ${NEWLINE}"

done < $input

#echo $output1 > pipesshellfs_tmp.out

#sed -i "s/<\"/touch/g" pipessshellfs_${PAR}_chunks.sh

#while read line
#do
	#if echo "$line" | grep -q "<"
	#then
			
	#fi	

#done < $output1

echo OUTPUT
echo ==================
echo -e $output1 > pipessshellfs_${PAR}_chunks.sh 

sed -i "s/\<mkfifo\>/touch/g" pipessshellfs_${PAR}_chunks.sh
