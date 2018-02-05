#!/bin/bash

#checking if for the command usage
if [[ $# -ne 3 ]]; then
	echo "USAGE: $0 username/UID groupname/GID abs=/directory_path or rel(wrt to pwd)=path"
	exit 1
fi


#checking if an executable file already exits or not
file="executable_files.txt"
if [[ -f "$file" ]];then
	rm "$file"

fi

#checking for the relative path with respect to the present working directory
main_path="$(pwd)"

user="$1"

#checking if the user is a valid user
getent passwd "$user" > /dev/null
if [[ $? -ne 0 ]];then
	echo "Not a valid user"
	exit 1
fi

#checking if a group is a valid group
group="$2"
getent group "$group" > /dev/null
if [[ $? -ne 0 ]]; then
	echo "Not a valid group"
	exit 1
fi

#checking is the user belongs to the  group
if ! [ $(getent group "$group"|grep "\b"${user}"\b") ] ; then
	
	echo "user not part of the group"
	exit 1
fi

path_input="$3"
path=""

#checking for relative or absolute path. Relative path is checked with respect to the present working directory. 
#if the path is relative then convertiing that to an absolute path
if [[ "$path_input" = /* ]]; then
	path="$path_input"
else
	path="$main_path"/"$path_input"
fi 

#checking if it is a valid directory or not
if ! [[ -d "$path" ]]; then
	echo "not a valid directory"
	exit 1
fi

file_info=""
file_exec="executable_files.txt"

#iterating through the results of the find command and checking for the user , group and other execute permission
# and updating the file "executable_files.txt with the result"
while read line
do
	check=0
	file_perm="$(echo "$line"|awk '{print $1}')"
	file_name="$(echo "$line"|awk '{print $9}')"
	u_perm="$(echo "$file_perm"|awk '{print substr($1,4,1)}')" #owner permission
	g_perm="$(echo "$file_perm"|awk '{print substr($1,7,1)}')" # group permission
	o_perm="$(echo "$file_perm"|awk '{print substr($1,10,1)}')" #other permission
	user1="$(echo "$line" |awk '{print $3}')" # owner of the file
	file_info="$file_name:$file_perm"	
	if [[ "$user" = "$user1" ]];then
		if [[ "$u_perm" = "x" ]]; then
			u_ex_status="YU"
		
		else
			u_ex_status="NN"
		fi
		file_info="$file_info:$u_ex_status"
		(( check++ ))
		
	fi
	
	group1="$(echo "$line" |awk '{print $4}')"
	if [[ "$group" = "$group1" ]];then
		if [[ "$g_perm" = "x" ]]; then
			g_ex_status="YG"
		else
			g_ex_status="NN"
		fi
		file_info="$file_info:$g_ex_status"
		(( check++ ))
	fi

	if [[ "$o_perm" = "x" ]]; then
		o_ex_status="YO"
		(( check++ ))
	else
		o_ex_status="NN"

	fi
	file_info="$file_info:$o_ex_status"
	if [[ $check -ne 0 ]]; then
		echo "$file_info">>$file_exec
	fi
	unset check	
	
done < <(find $path -type f -exec ls -l {} \; ) # find all the files in all the mentioned directory and subdirectories
exit
