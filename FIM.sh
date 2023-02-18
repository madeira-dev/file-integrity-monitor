#!/bin/bash

# this function will get the file checksum given the filepath as parameter
calculate_file_hash() { sum=`sha512sum $1 | awk '{ print $1 }'`; }

# function to check if baseline file already exists and if true, deletes it to write a new one from scratch
check_if_baseline_exists() {
	exists=`test -f "baseline.txt"`
	if $exists; then
		echo `rm baseline.txt`
	fi
}

write_to_baseline() { echo "$1|$2" >> baseline.txt; }

write_files_hashes_and_paths() {
	files=`ls monitored_files/`
	for file in $files
	do                                                              
		file_path=`readlink -f monitored_files/$file`
		calculate_file_hash "$file_path"                    
		file_hash=$sum
		write_to_baseline "$file_path" "$file_hash"
	done
}

get_files_hashes_and_paths() {
	files=`ls monitored_files/`                                                                          
	for file in $files
	do                                                  
		file_path=`readlink -f monitored_files/$file`           
		calculate_file_hash "$file_path"                        
		file_hash=$sum                                      
	done                                                        
}

echo "What would you like to do?"
echo -e "\tA) Collect new baseline."
echo -e "\tB) Begin monitoring files with saved baseline"
echo "Enter A or B:"
read user_input

if [ $user_input == "A" ] || [ $user_input == "a" ]; then
	check_if_baseline_exists
	write_files_hashes_and_paths
elif [ $user_input == "B" ] || [ $user_input == "b" ]; then
	declare -A file_hash_dict
	while IFS="|" read -r file_path file_hash; do
		file_hash_dict[$file_path]=$file_hash
	done < baseline.txt

	while true; do
	sleep 1s
	echo "Checking if files match..."
	
	files=`ls monitored_files/`
	for file in $files
	do
		file_path=`readlink -f monitored_files/$file`
		calculate_file_hash "$file_path"
		file_hash=$sum

		# checking if file exists and checking if it is in the previous created dictionary
		if [ -e $file_path ] && [ -z "${file_hash_dict[$file_path]+x}" ]; then
			echo "The file $file_path was added to the directory!"
		
		else
			# check if file has been changed
			if [ "${file_hash_dict[$file_path]}" = "$file_hash" ]; then
				# file not changed, all ok
				:
			else
				# file changed, notify user
				echo "The file $file_path has changed!"
			fi
		fi

		# checking if file has been deleted
		for key in "${!file_hash_dict[@]}"; do
			if [ ! -e "$key" ]; then
				echo "The file $key has been deleted"
			fi
		done
	done
done
else
    echo "Option not found"
fi

