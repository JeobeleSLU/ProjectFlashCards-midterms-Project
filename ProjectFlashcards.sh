

#this function is under construction :) 
file_path='./flashcardresources/flashcards/'
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
         print_center 'press 1 to create a new flash cards press'

         print_center 'press 2 to read a Flash Card press '

         print_center 'press 0 to exit the program press'

}
decideToCreate(){
        # Ask user if they want to store the QA pairs
        echo "Do you want to store the question and answer pairs for later use? (yes/no)"
        read store_qa

        # Define the file path
        if [ "$store_qa" == "yes" ]; then
            echo "Enter the filename for storing question and answer pairs (e.g., qa_pairs.txt):"
            read filename
            file_path="./flashcardresources/flashcards/$filename"
        else
            file_path="./flascardsresources/temp/qa_pairs_temp.txt"
        fi

        # Check if the file already exists
        if [ -f "$file_path" ]; then
            echo "Question and answer pairs file already exists. Do you want to overwrite it? (yes/no)"
            read overwrite
            if [ "$overwrite" == "no" ]; then
                exit 1
            fi
        fi

        # Create or clear the file to store QA pairs
        > "$file_path"
        while true; do
            # Prompt user for a definition
            echo "Enter a definition (or type 'quit' to exit):"
            read definition

            # Check if the user wants to quit
            if [[ "$definition" == "quit" ]]; then
                echo "Exiting..."
                break
            fi

            # Prompt user for a question related to the definition
            echo "Enter a question related to the definition:"
            read question

            # Prompt user for the answer to the question
            echo "Enter the answer to the question:"
            read answer

            # Write question and answer to the file
            echo "$definition:$question:$answer" >> "$file_path"

            echo "Question and answer saved successfully!"
        done

        echo "Question and answer pairs have been stored in: $file_path"

}
displayFilesInDirectory(){
        directory=$1
          find "$directory" -type f | while read -r file; do
         # Extract the filename using basename
        filename=$(basename "$file")
        # Print the filename
        print_center 'Select file'
        print_center ''
        print_center "$filename"
        done
}
startFlashCard(){
        clear
        displayFilesInDirectory 'flashcardresources/flashcards'
        read userInput
}

getUserInput(){
        read userInput
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

#for creating a leaderboard
askForUserName(){
        #checks if the leaderboard file is not present
        if [ ! -f ./flashcardresources/users/leaderborads.txt ];
        then
                touch ./flashcardresources/users/leaderborads.txt 
                touch ./flashcardresources/users/sorted-leaderborads.txt 
        fi 
        leaderboard=./flashcardresources/users/leaderborads.txt
        sort -t':' -k2 -nr ./flashcardresources/users/leaderborads.txt > ./flashcardresources/users/sorted-leaderborads.txt


        echo "Enter your Username"
        
        read userName | tr '[:upper:]' '[:lower:]'
        #checks if the inputted name is already on the leaderboards
         if grep -q "^$userName:" "$leaderboard"; then
        echo "Username already exists in the leaderboard."

        # Prompt user if they want to overwrite the name
        while true; do
            read -p "Do you want to overwrite the existing name? (yes/no): " overwrite
            case $overwrite in
                [Yy]* ) sed -i "/^$userName:/d" "$leaderboard"; echo "$userName:$score" >> "$leaderboard"; break;;
                [Nn]* ) break;;
                * ) echo "Please answer yes or no.";;
            esac
        done
    else
        echo "$userName:$score" >> "$leaderboard"
        echo "Username added to the leaderboard."
    fi
}

checkForResources(){
        #checks if the directory doesn't exist
       if [ ! -d flashcardresources/ ]; then 
       #create a nested directory flashcardresource >{users,flashcards>temp}
          mkdir -p flashcardresources/{users/,flashcards/temp} && touch ./flashcardresources/flashcards/temp/qa_pairs_temp.txt
        
        fi
}
clear
        checkForResources #checks if the flashcard resources dir is present  
        askForUserName
        
        while true; do
                
         print_center 'Welcome to the Louisian at Quiz!' 
                askUser
                getUserInput
        done
