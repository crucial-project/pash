#!/usr/bin/env bash

PAR=2

input=($@)

if [ $# -eq 0 ]
  then
    echo "No arguments supplied: abort"
    exit
fi

arrssh=()
while IFS= read -r line; do
  arrssh+=("$line")
done < configssh.txt

#root="/netfs/inf/amaheo/tmp"
root="netfs\/inf\/amaheo\/tmp"
NEWLINE='\n'

sendcmd="awk '{print \\\$0}END{print \\\"EOF\\\"}'"
recvcmd1="tail -n +0 --pid=\\$\\$ --retry"
recvcmd2="2>/dev/null | { sed '/EOF/ q' && kill \$\$ ;} | grep -v ^EOF\\$"

output="#!/usr/bin/env bash"
output="${output} ${NEWLINE}"
output="${output} ${NEWLINE}"

skippattern="/pash/runtime/eager.sh"

while read line
do

	#line=$(echo $line | sed "s/\/tmp/$root\/tmp/g")
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
echo -e $output > tmpsshellout

sed -i "s/tmp/${root}/g" tmpsshellout

tmpsshell=$(cat tmpsshellout)

csplit -z -f 'tempPASH' -b '%0d.txt' tmpsshellout /mkfifo_pash_fifos/ {*}

#rndm=($(shuf -e {00..12}))

while read line
do
	RANDOM=$(date +%s%N)
	sshmachine=${arrssh[$RANDOM % ${#arrssh[@]} ]}

	line=$(echo "$line" | sed -r "s/^[{]/{ ssh -tt amaheo@$sshmachine '/g")
	echo $line
        #echo $line | sed -r "s/&/' &/g"	

done < tempPASH2.txt > outfile

sed -i "s/&/' &/g" outfile

cat tempPASH0.txt > pipessshellfs.sh
cat tempPASH1.txt >> pipessshellfs.sh
cat outfile >> pipessshellfs.sh
