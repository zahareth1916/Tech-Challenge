#!/usr/bin/bash
# 06-07-2020

############################## BEGIN SCRIPT ##############################

#------ Begin Section 1 ------

declare -a timeArray #array for storing the time from the samples retrieved

durationSec=0;       #duration this script should run
pollingInterval=0;   #duration of each interval in seconds

newEpochDate=0;      #new ledger epoch time in seconds
oldEpochDate=0;      #storing the old ledger epoch time in seconds

i=0;                 #index variable
diff=0;              #difference in time in seconds for a ledger to validate in seconds
min=0;               #minimum difference in time it takes for ledgers to validate in seconds
max=0;               #maximum difference in time it takes for ledgers to validate in seconds
sum=0;               #total differences in time it takes for ledgers to validate in seconds
avg=0;               #average time it took for all the ledgers to validate in seconds

rm stats.txt         #delete the old stats.txt file
touch stats.txt      #create a new stats.txt file

read -p "Enter the (duration in seconds) of the samples you'd like to retrieve: " durationSec #storing the number of secs for the program to rum 
echo

read -p "Enter the (Polling interval in seconds) of the samples you'd like to retrieve: " pollingInterval #storing the number secs for the polling interval 
echo

echo "Time					Sequence" # displaying a header at the top of the output
echo "----					--------"

#------ End Section 1 ------

#----- Begin Section 2 -----

SECONDS=0 #start the timer

while [[ SECONDS -le $durationSec-$pollingInterval ]]
do
	#response="$(curl --silent 'Content-Type: application/json' -d '{"method":"server_info","params":[{}]}' https://s1.ripple.com:51234/ | jq -jr '.result.info.validated_ledger.seq,"\t",.result.info.time,"\t","\n"')" #retrieving the sequnce and date/time of the ledger for proccessing
	response="$(curl --silent 'Content-Type: application/json' -d '{"method":"server_info","params":[{}]}' https://s1.ripple.com:51234/ | jq -jr '.result.info.time,"\t\t",.result.info.validated_ledger.seq,"\n"')" #retrieving the date/time and sequnce of the validated ledger
	echo "$response";echo

	extractYear=$(echo "$response"|cut -b 1-4) #extracting the (year) from the response
	echo "$extractYear"

	extractMonth=$(echo "$response"|cut -b 6-8) #extracting the (month) from the response
	echo "$extractMonth"

	extractDay=$(echo "$response"|cut -b 10-11) #extracting the (day) from the response
	echo "$extractDay"

	extractTime=$(echo "$response"|cut -b 13-20) #extracting the (time) from the response
	echo "$extractTime"

	extractSequence=$(echo "$response"|cut -b 34-41) #extracting the sequence from the response
	echo "$extractSequence"

	newDateFormat="$extractDay"'-'"$extractMonth"'-'"$extractYear"' '"$extractTime" #assebling the new date format in the form of (dd-mmm-yyyy time) for the 'date' command below to change to epoch
	echo "$newDateFormat"

	newEpochDate=`date -d"${newDateFormat}" +%s` #change the new date format to epoch
	echo "$newEpochDate"

	newDateAndSequence="$newEpochDate""	""$extractSequence" #assemble the new epoch time and sequence respectively
	echo "$newDateAndSequence"

	echo "$newDateAndSequence" >> stats.txt
		
	#displaying on the screen what will be written to 'stats.txt'
	#swap="$newEpochDate"'	'"$extractSequence" #swaping the x and y axis 
	#echo "$swap" >> stats.txt #writing the output (date/time & sequence) to 'stats.txt'
	
	timeArray["$i"]="$newEpochDate" #storing the epoch time in corresponding element(i) of the time array

	if (( "$oldEpochDate" != 0 )); #prevent subtracting 0 (the initial old time value) from the new time
		then
		diff=$(( "${timeArray[$i]}" - "$oldEpochDate" )) #get the difference between the new and old time values
		echo "$diff"
	fi

    oldEpochDate="${timeArray[$i]}" #store the new time from element(i) in the old time variable

#------ End Section 2 ------ 

#----- Begin Section 3 -----

	if (( "$min" == 0 )) #comparing with min when min is initialised to '0' will not work! as '0' will always be the minimum, hence assigning the 1st difference value to min
		then
			if (( "$diff" > 0 ))
				then 
					min=$diff
			fi
	fi

	if (( "$min" > "$diff" )) #find the minimum difference
		then
			min=$diff
	fi

	if (( "$max" < "$diff" )) #find the maximum difference
		then
			max=$diff
	fi

	sum=$((sum+$diff)) #calculating the sum of all the time differences

	i=$((i+1)) #increment the index that will be used by the time array

	sleep $pollingInterval #polling interval in seconds
done

#------ End Section 3 ------ 

#----- Begin Section 4 -----

avg=$(echo "scale=2;" $sum/$i | bc -l) #calculate the average time

echo "-----------------------------------------------"
echo
echo "The entire array elements are: "${timeArray[@]}""
echo "In "$SECONDS" "Seconds""
echo
echo "-----------------------------------------------"
echo "Min = "$min""
echo
echo "Max = "$max""
echo
echo "Sum = "$sum""
echo
echo "Number of Instances = "$i""
echo
echo "Avg = Sum/instances = "$avg""
echo

#------ End Section 4 ------

############################## END SCRIPT ##############################