#! /bin/bash

Insert_record_function ()
{
# as input:record_name
# as input:record_amount
        # check valid string
        read -p "Insert Record Name: " rcd
        record_name_vld_function  $rcd
        while [ ! $rcdchk ]
        do
                read -p "Invalid Record Name. Insert Record Name:" rcd
                record_name_vld_function $rcd
        done
        # check valid number
        read -p "Insert Amount of Copies: " amount
        amount_vld_function $amount
        while [ ! $numchk ]
        do
                read -p "Insert Amount of Copies: " amount
                amount_vld_function $amount
        done

        Search_string_in_file $rcd
        if [ -z $record_name ]
        then
                echo "$rcd,$amount" >> $FILE
                #log new record
                echo "log new record $rcd,$amount"
        else
                PS3="Select existing record or N - new record: "
                select var in ${record_name[@]}
                do
                        echo $REPLY
                        case $REPLY in
                        N|n|new) echo "$rcd,$amount" >> $FILE
                        #log new record
                        echo "log new record $rcd,$amount"; break
                        ;;
                        *) amount_vld_function $REPLY
                        if [ $numchk ]
                        then
                                let REPLY-=1 #fix array usage
                                let amount+=${record_amount[$REPLY]}
                                sed -i "s/$var,${record_amount[$REPLY]}/$var,$amount/" $FILE
                                echo "'$var' amount has been updated from '${record_amount[$REPLY]}' to '$amount'"
                                Status="Success"
                                Write_to_record_log_function
                                break
                        else
                                echo "wrong selection! try again. Record: "
                        fi
                        ;;
                        esac
                done
        fi
}


Delete_record_function ()
{
# input1: ask for record_name
# input2: ask for record amount
# phase1- check inputs validation
# phase 2- search for record name
# phase 3 - delete/update the record

read -p "please insert record name to delete:" delete_record_name
record_name_vld_function $delete_record_name
while [ ! $rcdchk ]
do
        read -p "Invalid Record Name. Insert Record Name: " delete_record_name
        record_name_vld_function $delete_record_name
done
# check valid number 'delete_amount"
read -p "please insert the amount of Copies to delete: " delete_amount
amount_vld_function $delete_amount
while [ ! $numchk ]
do
        read -p "please insert the amount of Copies to delete: " delete_amount
        amount_vld_function $delete_amount
done
# search for delete_record_name:
Search_string_in_file $delete_record_name

if [ -z $record_name ]
then
# record not existed
        echo "the requested $delete_record_name is not exists"
else
        PS3="Select existing record "
        select var in ${record_name[@]}
        do
                let REPLY-=1
                let nAmount=${record_amount[$REPLY]}-$delete_amount
                if [ $nAmount -eq 0 ]
                then
                        sed -i "/$delete_record_name/d" $FILE
                elif [ $nAmount -gt 0 ]
                then
                        echo "update amount"
                else
                        echo "invalid amount requested to delete"
                fi
                break
        done
fi
}

Search_string_in_file ()
{
# as input:str from user
if [ $# -eq 0 ];
then
	read -p "Enter the record you search for: " user_input
else
	user_input=$1
fi
record_name_vld_function $user_input
IFS=','
x=$(cat $FILE |grep $user_input|cut -d ',' -f1|tr '\n' ',')
record_name=($x)
y=$(cat $FILE|grep $user_input|cut -d ',' -f2|tr '\n' ',')
record_amount=($y)
counter=${#record_name[@]}
i=0
if [[ $counter -ne 0 ]]; then
	while [[ $i -lt $counter && $# -eq 0 ]]
	do
			echo "$i. ${record_name[$i]},${record_amount[$i]}"
			let i=$i+1
	done
		echo "We found $counter results for '$user_input' "
	else
		echo "The search has failed."
fi
}

Update_record_name_function ()
{
#Ask for input, Old Name and New Name
#Use search function
#If 1 result update it
#If more than 1 result show a menu to choose from
#Else echo record doesn't exist

read -p "Please enter the Old Name: " old_name
read -p "Please enter the New Name: " new_name
Search_string_in_file $old_name
Action="UpdateName"
if [[ $counter -eq 1 ]]; then
	sed -i "s/${record_name[0]}/$new_name/" $FILE
	echo "'${record_name[0]}' has been updated to $new_name"
	Status="Success"
	Write_to_record_log_function
elif [[ $counter -gt 1 ]]; then
#SETTING STATUS
#IFS=','
#IF MORE THAN 1 RESULT MAKE A MENU
PS3="Choose an option or quit: "
option_to_quit="Quit"
Menu=$x$option_to_quit
select var in $Menu;
do
let count_from_zero=$REPLY-1
	sed -i "s/${record_name[$count_from_zero]}/$new_name/" $FILE
	echo "${record_name[$count_from_zero]} has been updated to $new_name"
	Status="Success"
	Write_to_record_log_function
	break;
done
#####	
else
	echo "The record name doesn't exist."
	Status="Failure"
	Write_to_record_log_function
fi
}

Update_record_amount_function ()
{
#UPDATE COUNT FUNCTION
#Ask for input, name and amount.
#Use search function
#If 1 result update it
#If more than 1 results show a menu to choose from
#If Amount less than 1 display "Error"
#Else echo record doesn't exist

read -p "Please Enter the Record Name: " rec_name
read -p "Please Enter the Record Amount: " rec_amount
Search_string_in_file $rec_name
Action="UpdateAmount"
if [[ $counter -eq 1 ]]; then
#SETTING STATUS
	sed -i "s/${record_amount[0]}/$rec_amount/" $FILE
	echo "'${record_name[0]}' amount has been updated from '${record_amount[0]}' to '$rec_amount'"
	Status="Success"
	Write_to_record_log_function
elif [[ $counter -gt 1 ]]; then
#IF MORE THAN 1 RESULT MAKE A MENU
PS3="Choose an option or quit: "
option_to_quit="Quit"
Menu=$x$option_to_quit
select var in $Menu;
do
let count_from_zero=$REPLY-1
	sed -i "s/${record_amount[$count_from_zero]}/$rec_amount/" $FILE
	echo "'${record_name[$count_from_zero]}' amount has been updated from '${record_amount[$count_from_zero]}' to '$rec_amount'"
	Status="Success"
	Write_to_record_log_function
	break;
done
else
	echo "Record doesn't exist, Error."
	Status="Failure"
	Write_to_record_log_function
fi
}

Print_total_amount_function ()
{
# no input parameters
# will take a records_file as input $1

#! /bin/bash
#check if file is empty

if  [ -s $1 ] 
then
	x=$(cat $1 | cut -d "," -f2)
	amount_arr=($x)
	amount_counter=0
	# let size=${#amount_arr[@]}-1
	
	for i in ${amount_arr[@]}
	do
		let amount_counter=$amount_counter+$i
	
	done
	if [ $amount_counter -gt 0 ]
	then 
		echo "the sum of all amounts is $amount_counter"
	fi
else
	echo "the file $1 is empty" 

fi
}

Print_sorted_record_file_function ()
{
# no input parameters
#check if file is empty
# will take a records_file as input $1
if  [ -s $1 ]
then
        echo $1 | sort -t "," -k1 $1
else
        echo "The file $1 is empty"
fi
}

Write_to_record_log_function ()
{
#input: action (insert,delete,search,updateName,...)
#input: status if passed or failed
#WRITE TO LOG FILE
#DISPLAY DATE TIME ACTION SUCCESS/FAILURE (except print functions)

echo -n $( date "+%D %T" ) >> recordFileName_log
echo " $Action $Status" >> recordFileName_log
}

record_name_vld_function()
{ 
#input:expression 
        REGEX="^[[:alnum:][:space:]]*$"
        if [[ $1 =~ $REGEX ]]
        then
                rcdchk=true
        else
                echo "invalid input"
                rcdchk=false
        fi
}

amount_vld_function()
{ 
#input: expression
        REGEX='^[[:digit:]]+$'
        if [[ $1 =~ $REGEX ]]
        then
                numchk=true
        else
                numchk=false
        fi


}




