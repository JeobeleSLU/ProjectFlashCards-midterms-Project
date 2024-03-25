

#this function is under construction :)
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
        clear
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
            file_path="$filename"
        else
            file_path="/tmp/qa_pairs_temp.txt"
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
getUserInput(){
        read userInput
        case $userInput in
                1)
                        decideToCreate
                        echo "Your input is 1"
                        ;;
                2)
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

clear
        echo "Welcome to the Louisian at Quiz!"
        while true; do
                askUser
                getUserInput
        done
