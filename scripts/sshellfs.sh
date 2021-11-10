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
#root="home\/aurele\/tmp"
NEWLINE='\n'

sendcmd="awk '{print \$0}END{print \\\"EOF\\\"}'"
recvcmd1="tail -n +0 -f --pid=\$\$ --retry"
recvcmd2="2>/dev/null | { sed /EOF/ q ;} | grep -v ^EOF\$"
recvcmd3="&& kill \$\$"

output="#!/usr/bin/env bash"
output="${output} ${NEWLINE}"
output="${output} ${NEWLINE}"

eagerpattern="/pash/runtime/eager.sh"
splitpattern="/pash/runtime/auto-split.sh"
sortmergepattern="sort -m"
newlinepattern="\\n"
awkpattern="awk"

while read line
do
	iterline=$(($iterline+1))

	#line=$(echo $line | sed "s/\/tmp/$root\/tmp/g")
	#line=$(echo $line | sed 's/\<mkfifo\>/install -Dv \/dev\/null/g')
	line=$(echo $line | sed 's/\<mkfifo\>/touch/g')
	line=$(echo $line | sed 's/</< /g')
	line=$(echo $line | sed 's/>"/> /g')
	line=$(echo $line | sed 's/"\//\//g')
	line=$(echo $line | sed 's/" ;/ ;/g')
	line=$(echo $line | sed 's/#fifo/fifo/g')
	line=$(echo $line | sed 's/" >/ >/g')
	line=$(echo $line | sed 's/" &/ &/g')
	line=$(echo $line | sed 's/" \/tmp/ \/tmp/g')
	line=$(echo $line | sed 's/"\\n"/\\\\newline/g')
	#line=$(echo $line | sed 's/"\[a/\\\"\[a/g')
	#line=$(echo $line | sed 's/tr -c "/trwd -c/g')i
	#line=$(echo $line | sed 's/"/\\\"/g')
	#line=$(echo $line | sed 's/[a-z]/[a-z]/g')
	line=$(echo $line | sed 's/]"/]\"/g')
	#line=$(echo $line | sed 's/"/\\\"/g')

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
			file2=$(echo $file2 | sed 's/" & }//g')
			echo file1: $file1
			echo file2: $file2
		
		fi
		output="${output} { ${recvcmd1} ${file1} ${recvcmd2} | ${cmd} | ${sendcmd} > ${file2} ${recvcmd3} \" & }"		
	
	elif echo "$line" | grep -q "$eagerpattern"
	then
		echo eager pattern detected	
	        IFS=', ' read -r -a arrayline <<< "$line"
		echo ${arrayline[1]}
		echo ${arrayline[2]}
		echo ${arrayline[3]}
                output="${output} { ${recvcmd1} ${arrayline[2]} ${recvcmd2} | ${sendcmd} > ${arrayline[3]} ${recvcmd3} \" & }" 
	
	elif echo "$line" | grep -q "$splitpattern"
	then
		echo auto-split pattern detected

		#fifoline=$(echo $line | grep "fifo")
		fifoline=$(echo $line | grep -oh "\w*fifo\w*") 
		echo line: $line
		echo fifoline: $fifoline
	       	IFS=', ' read -r -a arrayline <<< "$line"
		#arraylinefifo=$($arrayline | grep fifo)
		echo ${arrayline[1]}
		echo ${arrayline[2]}
		echo ${arrayline[3]}
		echo ${arrayline[4]}
		output="${output} ${line}"
		output="${output} ${NEWLINE}"
		output="${output} echo EOF >> ${arrayline[3]} ; echo EOF >> ${arrayline[4]} \""
		#for x in $(seq 3 ${#arrayline[@]})
		#do
			#output="${output} ; echo EOF >> ${arrayline[$x]} ; echo EOF >> ${arrayline[4]} \""
			#output="${output} ; echo EOF >> ${arrayline[$x]}  \""
		#done

	elif echo "$line" | grep -q "$sortmergepattern"
	then
		echo "sort merge pattern DETECTED"
	       	IFS=', ' read -r -a arrayline <<< "$line"
		echo ${arrayline[3]}
		echo ${arrayline[4]}
		echo ${arrayline[6]}
		
		output="${output} ${recvcmd1} ${arrayline[3]} ${recvcmd2} > ${arrayline[3]}_edit && ${recvcmd1} ${arrayline[4]} ${recvcmd2} > ${arrayline[4]}_edit && sort -m ${arrayline[3]}_edit ${arrayline[4]}_edit > ${arrayline[6]} && echo EOF >> ${arrayline[6]} && kill \\\$\\\$ \""

	elif echo "$line" | grep -q "$awkpattern"
	then
		echo "awk pattern DETECTED"
		line=$(echo $line | sed 's/"/'\''/g')
		echo $line
		output="${output} ${line}"

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

	line=$(echo $line | sed 's/"/\\\"/g')
	line=$(echo "$line" | sed -r "s/^[{]/{ nohup ssh -ntt amaheo@localhost \"/g")
	#line=$(echo "$line" | sed -r "s/& }/\" &/g")
	#line=$(echo "$line" | sed -r "s/\" \"/\\\\\" \\\\\"/g")
	#line=$(echo "$line" | sed -r "s/\\$\\$/\\\\$\\\\$/g")
	#line=$(echo "$line" | sed -r "s/EOF$/EOF\$/g")
	#line=$(echo "$line" | sed -r "s/print \\\"EOF\\\"/print \\\\\"EOF\\\\\"/g")
	#line=$(echo "$line" | sed -r "s/\\\$0/\\\\\$0/g")
	#line=$(echo "$line" | sed -r "s/\"EOF\"/\\\\\"EOF\\\\\"/g")
        #echo $line | sed -r "s/&/' &/g"

	if echo "$line" | grep -q "input"	
	then
		line=$(echo $line | sed 's/&//g')
		line=$(echo $line | sed 's/{//g')
		line=$(echo $line | sed 's/}//g')
	elif echo "$line" | grep -q "$splitpattern"
	then
		line=$(echo $line | sed 's/&//g')
		line=$(echo $line | sed 's/{//g')
		line=$(echo $line | sed 's/}//g')
	elif echo "$line" | grep -q "echo EOF"
	then
		line="nohup ssh -ntt amaheo@localhost \" ${line}"
	fi
	echo $line

done < tempPASH2.txt > tempPASH3.txt

while read line
do
	if echo "$line" | grep -q '.out '
	then
		#line=$(echo "wait ;" $line \")
		line=$(echo $line | sed 's/&//g')
		line=$(echo $line | sed 's/{//g')
		line=$(echo $line | sed 's/}//g')
	fi

	line=$(echo $line | sed 's/\$\$/\\\$\\\$/g')
	line=$(echo $line | sed 's/\" \"/\\\" \\\"/g')
	line=$(echo $line | sed 's/\$0/\\\$0/g')
	#line=$(echo $line | sed 's/^EOF$/^EOF\$/g')
	line=$(echo $line | sed 's/print "EOF"/print \\\"EOF\\\"/g')
	line=$(echo $line | sed 's/EOF\$/EOF\\\$/g')
	#line=$(echo $line | sed 's/"EOF\/ q"/\\\"EOF\/ q\\\"/g')
	line=$(echo $line | sed 's/\/EOF\/ q/\\\"\/EOF\/ q\\\"/g')
	line=$(echo $line | sed 's/tr -c "/tr -c \\\"/g')
	line=$(echo $line | sed 's/]"/]\\\"/g')
	line=$(echo $line | sed 's/newline/\\\"\\\\n\\\"/g')
	echo $line

done < tempPASH3.txt > outfile

#sed -i "s/.out/.out \"/g" outfile
#sed -i "s/\" & }/\"/g" outfile
#sed -i "s/& }/\"/g" outfile
#sed -i "s/\$\$/\$1\$1/g" outfile
#sed -i "s/newline/\"\\n\"/g" outfile
inputfile=$(basename $input)

cat tempPASH0.txt > sshellbackendfs_$inputfile
cat tempPASH1.txt >> sshellbackendfs_$inputfile
cat outfile >> sshellbackendfs_$inputfile

