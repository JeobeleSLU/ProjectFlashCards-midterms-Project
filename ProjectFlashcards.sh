#!/bin/bash
print_center(){ 

    [[ $# == 0 ]] && return 1


    declare -i TERM_COLS="$(tput cols)"

    declare -i str_len="${#1}"

    [[ $str_len -ge $TERM_COLS ]] && {

        echo "$1";

        return 0;

    }


    declare -i filler_len="$(( (TERM_COLS - str_len) / 2 ))"

    [[ $# -ge 2 ]] && ch="${2:0:1}" || ch=" "

    filler=""

    for (( i = 0; i < filler_len; i++ )); do

        filler="${filler}${ch}"

    done


    printf "%s%s%s" "$filler" "$1" "$filler"

    [[ $(( (TERM_COLS - str_len) % 2 )) -ne 0 ]] && printf "%s" "${ch}"

    printf "\n"


    return 0

}

#ask the user to input a username

askForUserName(){

    if [ ! -f ./flashcardresources/users/leaderboards.txt ]; then

        touch ./flashcardresources/users/leaderboards.txt

        touch ./flashcardresources/users/sorted-leaderboards.txt

    fi


    local leaderboard="./flashcardresources/users/leaderboards.txt"

    echo "Enter your Username"

    read -r userName

    userName=$(echo "$userName" | tr '[:upper:]' '[:lower:]')

    if grep -q "^$userName:" "$leaderboard"; then

        echo "Welcome back, $userName"

    else

        echo "$userName:0" >> "$leaderboard"

        echo "Username added to the leaderboard."

    fi

}


#ask the user what they want to do

askUser(){

    print_center 'Press 1 to Create new Flashcards'

    print_center 'Press 2 to Answer Flashcards'

    print_center 'Press 3 to View Leaderboard'

    print_center 'Press 0 to Exit the Program'

}



#main decision control for the program

getUserInput(){  

    read -r userInput

    case $userInput in

        1)

            decideToCreate

            ;;

        2)

            startFlashCard

            ;;

        3)

    viewLeaderboard

    ;;

        0)

            echo " Thank you for using Quizhard!"

            exit 0

            ;;

        *)

            echo "Invalid Input please try again"

            ;;

    esac

}

#ask the user if they want to store the file or its just for temporary use

decideToCreate(){

    clear

    echo "Do you want to store the question and answer pairs for later use? (yes/no)"

    read -r store_qa


#If the user wants to store the flash cards

    if [ "$store_qa" == "yes" ]; then

        echo "Enter the filename for storing question and answer pairs (e.g., qa_pairs.txt):"

        read -r filename #ask the user for the name of the flashcards

        file_path="./flashcardresources/flashcards/$filename" #store it inside the flashcards dir

    else

# if not, then store it as qa_pairs_temp.txt

        file_path="./flashcardresources/flashcards/qa_pairs_temp.txt" 

    fi


    if [ -f "$file_path" ]; then #if the flash cards already exist as the user to if they want to overwrite

        if [ "$store_qa" == "yes" ]; then

            echo "Question and answer pairs file already exists. Do you want to overwrite it? (yes/no)"

            read -r overwrite

            if [ "$overwrite" == "no" ]; then

                exit 1 

            fi

        else

            overwrite="yes"

        fi

    fi


    > "$file_path"

    while true; do

    #ask the user the question to store

        echo "Enter a question (or type 'quit' to exit):"

        read -r question

#checks if the user wants to quit, if they do then program will break

        if [[ "$question" == "quit" ]]; then

            echo "Exiting..."

            break

        fi

#ask the definition 

        echo "Enter the answer to the question:"

        read -r answer

#store the q&a in the provided format: question:answer

        echo "$question:$answer" >> "$file_path"


        echo "Question and answer saved successfully!"

    done


    if [ "$store_qa" == "yes" ]; then

        echo "Question and answer pairs have been stored in: $file_path"

    else

        echo "Temporary question and answer pairs have been stored in: $file_path"

    fi

}


#display all the flashcards for the user to select

displayFilesInDirectory(){

    local directory=$1

    print_center 'Select file'

    find "$directory" -type f | while read -r file; do

        filename=$(basename "$file") #strips the suffix of the file

    print_center ' '

    print_center "$filename" 

    done

}


#allow the user to answer flashcards

startFlashCard(){

    clear

    displayFilesInDirectory 'flashcardresources/flashcards'

    read -r flashcardFile

    local file_path="flashcardresources/flashcards/$flashcardFile"

    local totalQuestions=$(wc -l < "flashcardresources/flashcards/$flashcardFile")

    local correctAnswers=0

    while IFS=':' read -r -u 3 question answer; do

        echo "Question: $question"

        echo "(or enter 'skip' to move to another question)"

        echo "Enter your answer:"

        read -r userAnswer

        userAnswer=$(echo "$userAnswer" | tr '[:upper:]' '[:lower:]')

        answer=$(echo "$answer" | tr '[:upper:]' '[:lower:]')

        if [ "$userAnswer" == "$answer" ]; then

            echo "Correct!"

            correctAnswers=$(( correctAnswers + 1 ))

       elif [ "$userAnswer" == "skip" ]; then

    echo ""

        else

            echo "Incorrect."

        fi

    done 3< "flashcardresources/flashcards/$flashcardFile"


    echo "Score: $correctAnswers / $totalQuestions"

    calculateScoreAndUpdateLeaderboard "$totalQuestions" "$correctAnswers" "$userName"

}


#display leaderboard of users with their scores

viewLeaderboard(){

   local leaderboard="./flashcardresources/users/leaderboards.txt"

#sort -t: means use colon (:) as a delimiter to separate fields 

#-k2 means use the second column, -nr means sort using numerical values descending

   sort -t':' -k2 -nr ./flashcardresources/users/leaderboards.txt

}

updateScore() {
    local userName="$3"
    local correctAnswer="$1"
    local totalQuestions="$2"
    local leaderboard="./flashcardresources/users/leaderboards.txt"

    # Check if the user exists in the leaderboard
    local userExists=$(grep -c "^$userName:" "$leaderboard")

    if [ "$userExists" -eq 1 ]; then
        # If user exists, update the score
        awk -v userName="$userName" -v correctAnswer="$correctAnswer" -v totalQuestions="$totalQuestions" 'BEGIN{FS=OFS=":"} $1 == userName { $2 += correctAnswer; $3 += totalQuestions } 1' "$leaderboard" > "$leaderboard.tmp"
        mv "$leaderboard.tmp" "$leaderboard"
    else
        # If user doesn't exist, add a new entry
        echo "$userName:$correctAnswer/$totalQuestions" >> "$leaderboard"
    fi
}

calculateScoreAndUpdateLeaderboard() {
    local totalQuestions="$1"
    local correctAnswers="$2"
    local userName="$3"
    local leaderboard="./flashcardresources/users/leaderboards.txt"

    local score=$(( correctAnswers * 100 / totalQuestions ))

    updateScore "$correctAnswers" "$totalQuestions" "$userName"
}

calculateScoreAndUpdateLeaderboard $totalQuestions $correctAnswer "$userName"

#checks if the dir flashcardresources directory is not present

checkForResources(){ 

   if [ ! -d flashcardresources/ ]; then 

#creates the directory flashcardresources inside is the user dir and flashcard dir

        mkdir -p flashcardresources/{users/,flashcards/}    

fi

}



#clears the screen

clear

checkForResources #calls the function to create resources

askForUserName #calls the function to input name to the leaderboards


while true; do #main loop

    print_center 'Welcome to QUIZHARD Flashcards Program!' #display

    askUser #calls the function askUser

    getUserInput #calls the gerUserInput

done



