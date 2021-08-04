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

sendcmd="awk '{print \$0}END{print \"EOF\"}'"
recvcmd1="tail -n +0 --pid=\$\$ --retry"
recvcmd2="2>/dev/null | { sed '/EOF/ q' && kill \\$\\$ ;} | grep -v ^EOF\\$"

output="#!/usr/bin/env bash"
output="${output} ${NEWLINE}"
output="${output} ${NEWLINE}"

eagerpattern="/pash/runtime/eager.sh"

fifoSplitArray=()
fifoLineSplitArray=()
fifoSplitToReplaceArray=()
fifoLineSplitToReplaceArray=()
fifoLastArray=()
fifoLineLastArray=()
fifoLastToReplaceArray=()
fifoLineLastToReplaceArray=()
fifoSplitArrayLen=0
itersplitstr=0
sizeSplit=0
iterline=0
iterlineSplit=0
iterlineSource=0
iterlineLast=0

while read line
do
	iterline=$(($iterline+1))
	if echo "$line" | grep -q "split"
	then
	        IFS=', ' read -r -a arrayline <<< "$line"
		iterlineSplit=$iterline

                for index in "${!arrayline[@]}"
		do
			if echo "${arrayline[$index]}" | grep -q "fifo"
			then
				fifoSplitArray+=(${arrayline[$index]})
				continue
				itersplitstr=$index
				#echo Iter auto split location: $index			
			fi
		done

		#fifoSplitArrayLen=${!fifoSplitArray[@]}
		#sizeSplit=$(($fifoSplitArrayLen-1))
	fi

done < $input

# Remove first element
unset fifoSplitArray[0]
echo print fifo split array: ${fifoSplitArray[*]}

sizeSplit=${!fifoSplitArray[@]}

iterline=0
while read line
do
	iterline=$(($iterline+1))
	
        if [ $iterline -ge $iterlineSplit + 1 ] && [ $iterline -le $iterlineSplit + $sizeSplit ]
	then
	        IFS=', ' read -r -a arrayline <<< "$line"
		iterlineSplit=$iterline
		fifoLineSplitArrayToReplace+=$iterline

                for index in "${!arrayline[@]}"
		do
			if echo "${arrayline[$index]}" | grep -q "fifo"
			then
				fifoSplitArrayToReplace+=(${arrayline[$index]})	
				break
			fi	
		done
	fi

done < $input

iterline=0
while read line
do

	iterline=$(($iterline+1))

	if echo "$line" | grep -q "source"
	then
		iterlineSource=$iterline	
	fi	

done < $input

iterline=0
while read line
do
	iterline=$(($iterline+1))
	
	if $iterline -eq $iterlineSource-1
	then
		iterlineLast=$iterline
	        IFS=', ' read -r -a arrayline <<< "$line"

                for index in "${!arrayline[@]}"
		do
			if echo "${arrayline[$index]}" | grep -q "fifo"
			then
				fifoLastArray+=${arrayline[$index]}
			fi

		done
	fi

done < $input

iterline=0
while read line
do
	iterline=$(($iterline+1))
	fifoLastArrayToReplaceTmp=""

        if [ $iterline -le $iterlineLast - 1 ] && [ $iterline -ge $iterlineLast - $sizeSplit ]
	then
		IFS=', ' read -r -a arrayline <<< "$line"
		iterlineLast=$iterline
		fifoLineLastArrayToReplace+=$iterline

                for index in "${!arrayline[@]}"
		do
			if echo "${arrayline[$index]}" | grep -q "fifo"
			then
				fifoLastArrayToReplaceTmp=${arrayline[$index]}
				fifoLastArrayToReplace+=(${arrayline[$index]})	
			fi	
		done
		fifoLastArrayToReplace+=$fifoLastArrayToReplaceTmp	
	fi

done < $input

for index in "${!fifoSplitArray[@]}"
do
	fifoSplitArray[$index]=$(echo $fifoSplitArray[$index] | sed 's/"//g')	
	fifoSplitArray[$index]=$(echo $fifoSplitArray[$index] | sed 's/#fifo/fifo/g')	
done

for index in "${!fifoLastArray[@]}"
do
	fifoLastArray[$index]=$(echo $fifoLastArray[$index] | sed 's/"//g')	
	fifoLastArray[$index]=$(echo $fifoLastArray[$index] | sed 's/#fifo/fifo/g')	
done

echo Print fifoSplitArray ...
for index in "${!fifoSplitArray[@]}"
do
	echo $fifoSplitArray[$index]
done

echo Print fifoLastArray ...
for index in "${!fifoLastArray[@]}"
do
	echo $fifoLastArray[$index]
done

while read line
do
	echo $line

done < $input > output1

while read line
do
	iterline=$(($iterline+1))

	if echo "$line" | grep -q "$eagerpattern"
	then
		echo eager pattern detected	
	        IFS=', ' read -r -a arrayline <<< "$line"
		echo ${arrayline[1]}
		echo ${arrayline[2]}
		echo ${arrayline[3]}
                output="${output} { cp ${arrayline[2]} ${arrayline[3]} & }" 
	fi

	#line=$(echo $line | sed "s/\/tmp/$root\/tmp/g")
	line=$(echo $line | sed 's/\<mkfifo\>/touch/g')
	line=$(echo $line | sed 's/</< /g')
	line=$(echo $line | sed 's/>"/> /g')
	line=$(echo $line | sed 's/"\//\//g')
	line=$(echo $line | sed 's/" ;/ ;/g')
	line=$(echo $line | sed 's/#fifo/fifo/g')
	line=$(echo $line | sed 's/" >/>/g')
	line=$(echo $line | sed 's/" &/ &/g')
	line=$(echo $line | sed 's/" \/tmp/ \/tmp/g')

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

	line=$(echo "$line" | sed -r "s/^[{]/{ ssh -tt amaheo@$sshmachine \"/g")
	line=$(echo "$line" | sed -r "s/\\$\\$/\\\\$\\\\$/g")
	line=$(echo "$line" | sed -r "s/\\\$0/\\\\\$0/g")
	line=$(echo "$line" | sed -r "s/\"EOF\"/\\\\\"EOF\\\\\"/g")
        #echo $line | sed -r "s/&/' &/g"	
	if echo "$line" | grep -q "input"	
	then
		line=$(echo $line | sed 's/&//g')
		line=$(echo $line | sed 's/{//g')
		line=$(echo $line | sed 's/}//g')
	fi
	echo $line

done < tempPASH2.txt > outfile

sed -i "s/\" & }/\"/g" outfile
sed -i "s/& }/\"/g" outfile
#sed -i "s/\$\$/\$1\$1/g" outfile

cat tempPASH0.txt > pipessshellfs.sh
cat tempPASH1.txt >> pipessshellfs.sh
cat outfile >> pipessshellfs.sh

