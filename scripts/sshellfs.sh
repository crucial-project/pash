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

output="#!/usr/bin/env bash"
output="${output} ${NEWLINE}"
output="${output} ${NEWLINE}"

skippattern="/pash/runtime/eager.sh"

#while read line
#do
	#if echo "$line" | grep -q "$skippattern"
	#then
	#	continue
	#fi

	#output1="${output1} ${line}"
	#output1="${output1} ${NEWLINE}"

#done < $input 

#echo -e $output1 > pipesshellfs_tmp.out

#sed -i "s/</< /g" pipesshellfs_tmp.out
#sed -i "s/>/> /g" pipesshellfs_tmp.out

#sed -i "s/<\"/touch/g" pipessshellfs_${PAR}_chunks.sh

while read line
do
	line=$(echo $line | sed 's/\<mkfifo\>/touch/g')
	line=$(echo $line | sed 's/</< /g')
	line=$(echo $line | sed 's/>/> /g')

	if echo "$line" | grep -q "<"
	then
		IFS='<' read -r cmd subline <<< "$line"
		cmd=$(echo $cmd | sed 's/{/ /g')
 		echo command: $cmd
		echo line1: $subline
		#cmd=$arrayline[1]
		#file1=$arrayline[3]
		#file2=$arrayline[5]

		if echo "$subline" | grep -q ">"
		then
			IFS='>' read -r file1 file2 <<< "$subline"
			file2=$(echo $file2 | sed 's/& }//g')
			echo file1: $file1
			echo file2: $file2

		fi
		output="${output} { ${recvcmd1} ${file1} ${recvcmd2} | ${cmd} | ${sendcmd} > ${file2} & }"			
	else	
		output="${output} ${line}"
	fi

	output="${output} ${NEWLINE}"

done < $input

echo OUTPUT
echo ==================
echo -e $output > pipessshellfs_chunks.sh 

