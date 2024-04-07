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

askUser(){
    print_center 'Press 1 to Create new Flashcards'
    print_center 'Press 2 to Answer Flashcards'
    print_center 'Press 0 to Exit the Program'
}

decideToCreate(){
    echo "Do you want to store the question and answer pairs for later use? (yes/no)"
    read -r store_qa

    if [ "$store_qa" == "yes" ]; then
        echo "Enter the filename for storing question and answer pairs (e.g., qa_pairs.txt):"
        read -r filename
        file_path="./flashcardresources/flashcards/$filename"
    else
        file_path="./flashcardresources/flashcards/temp/qa_pairs_temp.txt"
    fi

    if [ -f "$file_path" ]; then
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
        
        echo "Enter a question (or type 'quit' to exit):"
        read -r question

        if [[ "$question" == "quit" ]]; then
            echo "Exiting..."
            break
        fi

        echo "Enter the answer to the question:"
        read -r answer

        echo "$question:$answer" >> "$file_path"

        echo "Question and answer saved successfully!"
    done

    if [ "$store_qa" == "yes" ]; then
        echo "Question and answer pairs have been stored in: $file_path"
    else
        echo "Temporary question and answer pairs have been stored in: $file_path"
    fi
}


displayFilesInDirectory(){
    local directory=$1
    find "$directory" -type f | while read -r file; do
        filename=$(basename "$file")
        print_center 'Select file'
        print_center ''
        print_center "$filename"
    done
}

getUserInput(){
    read -r userInput
    case $userInput in
        1)
            decideToCreate
            echo "Your input is 1"
            ;;
        2)
            startFlashCard
            echo "Your Input is 2"
            ;;
        0)
            echo " Thank you for using quickie quiz "
            exit 0
            ;;
        *)
            echo "Invalid Input please try again"
            ;;
    esac
}

updateScore() {
    local userName="$1"
    local score="$2"
    local leaderboard="./flashcardresources/users/leaderboards.txt"

    sed -i "/^$userName:/d" "$leaderboard"
    echo "$userName:$score" >> "$leaderboard"
}

calculateScoreAndUpdateLeaderboard() {
    local totalQuestions="$1"
    local correctAnswers="$2"
    local userName="$3"
    local leaderboard="./flashcardresources/users/leaderboards.txt"

    local score=$(( correctAnswers * 100 / totalQuestions ))
    updateScore "$userName" "$score"
}

askForUserName(){
    if [ ! -f ./flashcardresources/users/leaderboards.txt ]; then
        touch ./flashcardresources/users/leaderboards.txt
        touch ./flashcardresources/users/sorted-leaderboards.txt
    fi

    local leaderboard="./flashcardresources/users/leaderboards.txt"
    sort -t':' -k2 -nr ./flashcardresources/users/leaderboards.txt 

    echo "Enter your Username"
    read -r userName
    userName=$(echo "$userName" | tr '[:upper:]' '[:lower:]')
    if grep -q "^$userName:" "$leaderboard"; then
        echo "Username already exists in the leaderboard."
    else
        echo "$userName:0" >> "$leaderboard"
        echo "Username added to the leaderboard."
    fi
}

checkForResources(){
    if [ ! -d flashcardresources/ ]; then
        mkdir -p flashcardresources/{users/,flashcards/temp} && touch ./flashcardresources/flashcards/temp/qa_pairs_temp.txt
    fi
}

startFlashCard(){
    clear
    displayFilesInDirectory 'flashcardresources/flashcards'
    read -r flashcardFile
    local totalQuestions=$(wc -l < "flashcardresources/flashcards/$flashcardFile")
    local correctAnswers=0
    while IFS=':' read -r definition question answer; do
        echo "Question: $question"
        echo "Enter your answer:"
        read -r userAnswer

        if [ "$userAnswer" == "$answer" ]; then
            echo "Correct!"
            correctAnswers=$(( correctAnswers + 1 ))
        else
            echo "Incorrect."
        fi
    done < "flashcardresources/flashcards/$flashcardFile"

    echo "Score: $correctAnswers / $totalQuestions"
    calculateScoreAndUpdateLeaderboard "$totalQuestions" "$correctAnswers" "$userName"
}

# Call the main function
clear
checkForResources
askForUserName

while true; do
    print_center 'Welcome to the Louisian at Quiz!'
    askUser
    getUserInput
done