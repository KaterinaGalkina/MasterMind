#!/bin/bash

# Color codes
magenta='\033[0;35m'
green='\033[0;32m'
yellow='\033[1;33m'
cyan='\033[1;36m'
pc='\033[0m'

# Checks if the lists passed as parameters are identical, returns 1 if yes, otherwise 0
function compare_lists {
    local list1=("${!1}")
    local list2=("${!2}")
    local size=$3

    for ((i = 0; i < size; i++)); do
        if [ "${list1[$i]}" -ne "${list2[$i]}" ]; then
            return 0  
        fi
    done
    return 1 
}

# Checks if the character passed as parameter is a digit
# Returns 2 if it is a digit but strictly greater than max digit
# 1 if it is not a digit and 0 if it is indeed a digit between 0 and max digit
function is_digit {
    local char="$1"
    local digits="123456789"
    if [[ "$char" =~ ^[1-9]$ ]]; then
        if (( char > $ChiffreMax )); then
            return 2
        else
            return 0
        fi
    else
        return 1
    fi
}

# Checks if the string passed as parameter is written in the correct format
# (no separators, all contiguous, composed of digits) 
# Returns 1 if the string is well-written and 0 otherwise
function are_digits {  
    local try="$1"
    for ((i = 0; i < ${#combiSecrete[@]}; i++)); do
        is_digit ${try:i:1} 
        val=$?
        if [ $val -eq 1 ]; then
            echo -e "\n${magenta}Attention!${pc} A combination must be written without separators, all contiguous, without additional characters!\n"
            return 1
        elif [ $val -eq 2 ]; then
            echo -e "\n${magenta}Attention!${pc} All digits in your combination must be between 1 and $ChiffreMax!\n"
            return 1
        fi
    done
    return 0
}

function turn {
    local secret=("${!1}")
    local histo=("${!2}")
    error=1
    while [ $error -eq 1 ]; do
        echo "Please enter your guess: "
        read attempt

        if [ ${#attempt} -ne $numberOfDigits ]; then
            echo -e "\n${magenta}Attention!${pc} Your entered combination is of incorrect length!"
            echo -e "The combination must be composed of ${#secret[@]} digits from 1 to $ChiffreMax\n"
        else 
            error=0
        fi
    done

    error=1
    while [ $error -eq 1 ]; do
        are_digits attempt[@]
        val=$?
        if [ $val -eq 0 ]; then
            error=0
        else 
            echo "Please enter your guess: "
            read attempt
        fi
    done

    guessList=()

    for ((i=0; i<${#attempt}; i++)); do
        digit=${attempt:i:1}  
        integer=$(($digit)) 
        guessList+=("$integer")
    done

    compare_lists guessList[@] secret[@] "${#guessList[@]}"
    result=$?

    if [ $result -eq 1 ]; then
        echo -e "\n${green}Congratulations!${pc} You guessed it right, it was ${cyan}${secret[@]}${pc}\n"
        return 0
    fi

    if [ $result -eq 0 ]; then

        correctlyPlaced=0
        incorrectlyPlaced=0
        histogram=("${histo[@]}")
        
        for ((i=0; i<${#guessList[@]}; i++)); do
            if [ "${guessList[$i]}" -eq "${secret[$i]}" ]; then
                ((correctlyPlaced++))
                ((histogram[$((${guessList[$i]}-1))]--))
            fi
        done

        for ((i=0; i<${#guessList[@]}; i++)); do
            if [ "${guessList[$i]}" -ne "${secret[$i]}" ] && [ "${histogram[$((${guessList[$i]}-1))]}" -gt 0 ]; then
                ((incorrectlyPlaced++))
                ((histogram[$((${guessList[$i]}-1))]--))
            fi
        done

        echo -e "\nNumber of ${green}correctly placed${pc} elements: $correctlyPlaced"
        echo -e "Number of ${cyan}incorrectly placed${pc} elements: $incorrectlyPlaced"
    fi
    return 1
}

function game {
    local players=("${!1}")
    local secret=("${!2}")
    local currentHistogram=("${!3}")
    local numPlayers=${#players[@]}
    local numberOfAttempts=10
    local result=1
    # In case there are multiple players
    if [ $numPlayers -ne 0 ]; then   
        while [ $numberOfAttempts -gt 0 ]; do
            for k in $(seq 0 $(($numPlayers-1))); do 
                echo -e "\nIt's ${yellow}${players[$k]}${pc}'s turn!\n"
                turn secret[@] currentHistogram[@]
                result=$?
                if [ $result -eq 0 ]; then 
                    break 2
                fi 
                if [ $numberOfAttempts -eq 1 ]; then
                    echo -e "\n${magenta}Too bad!${pc} ${players[$k]}, you lost, you have no more attempts!"
                    if [ $k -eq $(($numPlayers-1)) ]; then 
                        echo -e "\nAll players lost...\n"
                        echo -e "The secret combination was ${secret[@]}\n"
                    fi
                else 
                    echo -e "You still have ${magenta}$(($numberOfAttempts-1))${pc} attempts\n"
                fi 
            done
            numberOfAttempts=$((numberOfAttempts - 1))
        done
    # In case there's only one player
    else             
        while [ $numberOfAttempts -gt 0 ]; do
            turn secret[@] currentHistogram[@]
            result=$?
            if [ $result -eq 0 ]; then 
                break 
            fi 
            if [ $numberOfAttempts -eq 1 ]; then
                echo -e "\n${cyan}Too bad!${pc} You lost, you have no more attempts!"
                echo -e "The secret combination was ${secret[@]}\n"
            else 
                echo -e "You still have ${magenta}$(($numberOfAttempts-1))${pc} attempts\n"
            fi 
            numberOfAttempts=$((numberOfAttempts - 1))
        done
    fi
}
clear
echo -e "\nDo you want to play alone or with your friends?"
echo "If with friends, type '1', if alone type '0'"
read rep
players=()
if [ "$rep" -eq 1 ]; then 
    error=1
    while [ $error -eq 1 ]; do
        echo -e "\nEnter the number of players: "
        read numPlayers
        if [[ $numPlayers =~ ^[0-9][0-9]*$ ]]; then
            numPlayers=$((numPlayers))
            error=0
        else
            echo -e "\n${magenta}Attention!${pc} The number of players must be a positive integer."
            echo "Please enter it again"
        fi 
    done
    echo -e "\nEnter the names of players one by one in the order you want to play :"
    for ((i=1; i<=$((numPlayers)); i++)); do
        echo -e "\nPlayer n$i :"
        read player
        players+=("$player")
    done
fi 

error=1
while [ $error -eq 1 ]; do
    echo -e "\nEnter the length of a combination you want to guess: "
    read nb
    if [[ $nb =~ ^[0-9]+$ ]]; then
        numberOfDigits=$((nb))
        error=0
    else
        echo -e "\n${magenta}Attention!${pc} The length of a combination must be a positive integer."
        echo -e "Please enter it again\n"
    fi
done


error=1
while [ $error -eq 1 ]; do
    echo -e "\nEnter the maximum digit that can be present in your combination (from 1 to 9)"
    read nb
    if [[ $nb =~ ^[1-9]$ ]]; then
        ChiffreMax=$((nb))
        error=0
    else
        echo -e "\n${magenta}Attention!${pc} The maximum digit entered is incorrect!"
        echo -e "It must be between 1 and 9!\n"
        echo "Please enter it again"
    fi
done

while [ 1 -eq 1 ]; do

    # Generating the new secret combination
    secretCombination=()
    for i in $(seq 1 $numberOfDigits); do
        random_number=$((1+$((RANDOM % (ChiffreMax)))))
        secretCombination+=($random_number)
    done

    # and its associated histogram
    combinationHistogram=()
    for i in $(seq 0 $(($ChiffreMax-1)));
    do
        combinationHistogram+=(0)
    done

    for i in $(seq 1 $ChiffreMax);
    do
        for j in $(seq 0 $((${#secretCombination[@]}-1)))
        do
            if [ "${secretCombination[j]}" -eq "$i" ]; then
                combinationHistogram[i-1]=$((combinationHistogram[i-1]+1))
            fi
        done
    done

    clear

    echo -e "\n${yellow}Recap!${pc}: You have chosen a combination of length equal to $numberOfDigits"
    echo "All digits of this combination will be between 1 and $ChiffreMax"
    echo "Your combination of digits must be written without separators, all contiguous." 
    echo "For example, If the length is 4 and the maximum digit is 5, then your guess can be '3215'"
    echo -e "\n${cyan}The game begins!${pc}\n"

    game players[@] secretCombination[@] combinationHistogram[@]

    echo "Do you want to play again?"
    echo "Type '1' for yes or '0' for no"
    read rep
    if [ "$rep" -eq "0" ]; then
        break;
    else 

        echo -e "\nDo you want to change the maximum digit or the length of the sequence?"
        echo "Type '1' for yes or '0' for no"
        read rep
        if [ "$rep" -eq "1" ]; then

            error=1
            while [ $error -eq 1 ]; do
                echo -e "\nEnter the length of a combination you want to guess: "
                read nb
                if [[ $nb =~ ^[0-9]+$ ]]; then
                    numberOfDigits=$((nb))
                    error=0
                else
                    echo -e "\n${magenta}Attention!${pc} The length of a combination must be a positive integer.\n"
                    echo "Please enter it again"
                fi
            done

            error=1
            while [ $error -eq 1 ]; do
                echo -e "\nEnter the maximum digit that can be present in your combination (from 1 to 9)"
                read nb
                if [[ $nb =~ ^[1-9]$ ]]; then
                    ChiffreMax=$((nb))
                    error=0
                else
                    echo -e "\n${magenta}Attention!${pc} The maximum digit entered is incorrect!"
                    echo -e "It must be between 1 and 9!\n"
                    echo "Please enter it again"
                fi
            done
        fi 
        echo -e "\nDo you want to change the number of players?"
        echo "Type '1' for yes or '0' for no"
        read rep
        if [ "$rep" -eq "1" ]; then 
            echo -e "\nDo you want to play alone or with your friends?"
            echo "If with friends, type '1', if alone type '0'"
            read rep
            players=()
            if [ "$rep" -eq 1 ]; then 

                error=1
                while [ $error -eq 1 ]; do
                    echo -e "\nEnter the number of players: "
                    read numPlayers
                    if [[ $numPlayers =~ ^[0-9][0-9]*$ ]]; then
                        numPlayers=$((numPlayers))
                        error=0
                    else
                        echo -e "\n${magenta}Attention!${pc} The number of players must be a positive integer.\n"
                        echo "Please enter it again"
                    fi 
                done

                echo -e "\nEnter the names of players one by one in the order you want to play :"
                for ((i=1; i<=$((numPlayers)); i++)); do
                    echo -e "\nPlayer n$i :"
                    read player
                    players+=("$player")
                done
            fi 
        fi 
    fi
done