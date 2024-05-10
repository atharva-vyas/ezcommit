#!/bin/bash

# ANSI color codes
# Regular colors
BLACK='\033[0;30m'
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[0;37m'

# Bold colors
BOLD_BLACK='\033[1;30m'
BOLD_RED='\033[1;31m'
BOLD_GREEN='\033[1;32m'
BOLD_YELLOW='\033[1;33m'
BOLD_BLUE='\033[1;34m'
BOLD_MAGENTA='\033[1;35m'
BOLD_CYAN='\033[1;36m'
BOLD_WHITE='\033[1;37m'

# Reset color
NC='\033[0m' # No Color



# Function to get the authenticated GitHub username
get_username() {
    # Path to the GitHub configuration file
    config_file="/root/.config/gh/hosts.yml"

    # Check if the config file exists
    if [ ! -f "$config_file" ]; then
        echo "Error: Configuration file '$config_file' not found."
        exit 1
    fi

    # Get current authenticated user from YAML file
    current_user=$(awk '/^ *user:/{print $2}' "$config_file")

    # Check if the username is empty
    if [ -z "$current_user" ]; then
        echo "Error: No user found in the configuration file."
        exit 1
    fi

    echo $current_user
}

# Call the get_username function and assign the result to the username variable
username="$(get_username)"


# Function to extract the repository name from a given path
extract_repo_name() {
    # Get the user input passed to the function
    local user_input=$1

    # Define a function to extract the last part of a path
    extract_last_part() {
        local path=$1
        # Remove trailing slashes if any
        path=${path%/}
        # Extract the last part after the last slash
        echo "${path##*/}"
    }

    # Call the extract_last_part function to extract the last part of the user input
    last_part=$(extract_last_part "$user_input")

    # Function to check if the given path is a valid directory
    is_valid_directory() {
        local dir=$1
        # Check if the directory exists
        if [ -d "$dir" ]; then
            # If directory exists, return the last part (repository name)
            echo $last_part
        else
            # If directory does not exist, display error message and exit
            echo "Directory '$dir' does not exist or is not valid."
            exit 1
        fi
    }

    # Call the is_valid_directory function to check if the given path is a valid directory
    is_valid_directory "$user_input"
}

# Prompt user for directory path
echo "Please provide a directory path"
read -p "('./' for current directory): " directory_path

# If directory path is './', update it to current directory path
if [ $directory_path == "./" ]; then
    directory_path=$(pwd)
fi

# Extract repository name from directory path
repo_name="$(extract_repo_name "$directory_path")"

# Function to check if .gitignore file exists in the directory
check_gitignore() {
    if [ -e "$directory_path/.gitignore" ]; then
        echo true
    else
        echo false
    fi
}

# Function to check if .git directory exists in the directory
check_gitinit() {
    if [ -e "$directory_path/.git/" ]; then
        echo true
    else
        echo false
    fi
}


# Function to print menu options
print_menu() {
    local print_numbers=$1

    echo ""

    # If print_numbers is true, print options with numbers
    if [ $print_numbers ]; then
        echo -e "${BOLD_BLUE}${BOLD_WHITE}Branch=> ${GREEN}$branch"
        # Check if git is initialized
        if [ ${git_init} == false ]; then
            echo -e "${BOLD_BLUE}${BOLD_WHITE}Initialize a new git repo (you will lose all your past commits)=> ${RED}$git_init"
        else
            echo -e "${BOLD_BLUE}${BOLD_WHITE}Initialize a new git repo (you will lose all your past commits)=> ${GREEN}$git_init"
        fi

        # Check if gitignore is set
        if [ ${git_ignore} == false ]; then
            echo -e "${BOLD_BLUE}${BOLD_WHITE}Add/edit .gitignore=> ${RED}$git_ignore"
        else
            echo -e "${BOLD_BLUE}${BOLD_WHITE}Add/edit .gitignore=> ${GREEN}$git_ignore"
        fi

        # Check if copy_to_before_commit is set
        if [ ${copy_to_before_commit} == false ]; then
            echo -e "${BOLD_WHITE}Don't push from source dir=> ${RED}$copy_to_before_commit"
        else
            echo -e "${BOLD_WHITE}Don't push from source dir=> ${GREEN}$copy_to_before_commit"
        fi

    # If print_numbers is not true, print options with numbers and bold colors
    else
        echo -e "${BOLD_BLUE}[1] ${BOLD_WHITE}GitHub Repo=> ${GREEN}$github_repo${NC}"
        echo -e "${BOLD_BLUE}[2] ${BOLD_WHITE}Branch=> ${GREEN}$branch"
        # Check if git is initialized
        if [ ${git_init} == false ]; then
            echo -e "${BOLD_BLUE}[3] ${BOLD_WHITE}Initialize a new git repo (you will lose all your past commits)=> ${RED}$git_init"
        else
            echo -e "${BOLD_BLUE}[3] ${BOLD_WHITE}Initialize a new git repo (you will lose all your past commits)=> ${GREEN}$git_init"
        fi

        # Check if gitignore is set
        if [ ${git_ignore} == false ]; then
            echo -e "${BOLD_BLUE}[4] ${BOLD_WHITE}Add/edit .gitignore=> ${RED}$git_ignore"
        else
            echo -e "${BOLD_BLUE}[4] ${BOLD_WHITE}Add/edit .gitignore=> ${GREEN}$git_ignore"
        fi

        # Check if copy_to_before_commit is set
        if [ ${copy_to_before_commit} == false ]; then
            echo -e "${BOLD_BLUE}[5] ${BOLD_WHITE}Don't push from source dir=> ${RED}$copy_to_before_commit"
        else
            echo -e "${BOLD_BLUE}[5] ${BOLD_WHITE}Don't push from source dir=> ${GREEN}$copy_to_before_commit"
        fi

        echo -e "${BOLD_BLUE}[6] ${BOLD_RED}Exit"
    fi
}



# Function to edit .gitignore file
edit_gitignore() {
    # Function to apply default patterns to .gitignore
    apply_gitignore_defaults() {
        # Define the contents of the .gitignore file in a single line
        local gitignore_content=".vscode/ .idea/ *.iml *.ipynb_checkpoints/ *.class *.jar *.war *.ear *.zip *.tar.gz *.rar *.log *.tmp .env .env.* node_modules/ vendor/ .DS_Store Thumbs.db config.ini secrets.json"
        
        # Convert the single line content to multi-line content
        local multi_line_content=$(echo "$gitignore_content" | sed 's/ /\n/g')
        
        # Write the contents to .gitignore file
        echo "$multi_line_content" >> .gitignore
    }

    # Function to prompt user to choose what type of pattern to ignore
    choose_ignore_type() {
        echo ""
        echo ""
        echo "What type of pattern would you like to ignore?"
        echo "1. Directory"
        echo "2. File Extension"
        echo "3. File Name"
        echo "4. Custom Pattern"
        echo "5. Use Defaults"
        echo "6. Exit"

        echo ""
        read -p "Enter your choice (1-6): " option_two
        if [ "${option_two}" == "1" ]; then
            read -p "Enter directory name to ignore: " pattern
            echo "$pattern/" >> .gitignore
            choose_ignore_type
        elif [ "${option_two}" == "2" ]; then
            read -p "Enter file extension to ignore (e.g., .log): " pattern
            echo "*$pattern" >> .gitignore
            choose_ignore_type
        elif [ "${option_two}" == "3" ]; then
            read -p "Enter file name to ignore: " pattern
            echo "$pattern" >> .gitignore
            choose_ignore_type
        elif [ "${option_two}" == "4" ]; then
            read -p "Enter custom pattern to ignore: " pattern
            echo "$pattern" >> .gitignore
            choose_ignore_type
        elif [ "${option_two}" == "5" ]; then
            apply_gitignore_defaults
            echo "Applied Defaults"
            choose_ignore_type
        elif [ "${option_two}" == "6" ]; then
            echo "Exiting..."
        else
            echo "Invalid choice. Please enter a number from 1 to 6."
            choose_ignore_type
        fi
    }

    # Check if .gitignore file exists
    if [ -e $directory_path"/.gitignore" ]; then
        echo ".gitignore file already exists."
        read -p "Do you want to create a new .gitignore file or append to the existing one? (create[1]/append[2]): " option
        if [ "$option" == "1" ]; then
            rm .gitignore
            echo "Creating a new .gitignore file."
            choose_ignore_type
        elif [ "$option" == "2" ]; then
            echo "Appending to the existing .gitignore file."
            choose_ignore_type
        else
            echo "Invalid option. Exiting..."
        fi
    else
        echo "Appending to a new .gitignore file."
        choose_ignore_type
    fi
}

# Function to prompt user for copying files to a temporary directory before committing
copy_before_commit() {
    echo -e "${NC}Would you like to copy files to a temp directory before pushing?"
    read -p "please type the temporary directory path [default => /git_temp] (y/n): " dir_copy_to_before_commit

    if [ "$dir_copy_to_before_commit" == "y" ]; then
        copy_to_before_commit="/git_temp"
        # If the directory doesn't exist, create it
        if [ ! -d "$copy_to_before_commit" ]; then
            mkdir -p "$copy_to_before_commit"
        fi

    elif [ "$dir_copy_to_before_commit" == "n" ]; then
        $copy_to_before_commit= false

    else
        copy_to_before_commit=$dir_copy_to_before_commit
        # If the directory doesn't exist, create it
        if [ ! -d "$copy_to_before_commit" ]; then
            mkdir -p "$copy_to_before_commit"
        fi
    fi
}

# Function to edit default settings
edit_defaults() {
    echo ""
    print_menu

    echo -e "${NC}"
    read -p "Select which option you want to change: " option_one

    if [ "${option_one}" == "1" ]; then
        read -p "Enter GitHub repository name: " new_repo_name
        repo_name="${new_repo_name}"
        github_repo="https://github.com/$username/$repo_name"
        edit_defaults

    elif [ "${option_one}" == "2" ]; then
        read -p "Enter branch name: " new_branch_name
        branch="${new_branch_name}"
        edit_defaults

    elif [ "${option_one}" == "3" ]; then
        read -p "Initialize new git repo, you will lose all your progress. (y/n): " new_git_init
        if [ "${new_git_init}" == "y" ]; then
            git_init=true
        else
            git_init=false
        fi
        edit_defaults

    elif [ "${option_one}" == "4" ]; then
        edit_gitignore
        edit_defaults

    elif [ "${option_one}" == "5" ]; then
        copy_before_commit
        edit_defaults

    elif [ "${option_one}" == "6" ]; then
        main_menu
    fi
}

# Function to copy files to a directory
copy_to_directory() {
    # Check if copy_to_before_commit is not equal to directory_path
    if [ "$copy_to_before_commit" != "$directory_path" ]; then
        # If the directory doesn't exist, create it
        if [ ! -d "$copy_to_before_commit" ]; then
            mkdir -p "$copy_to_before_commit"
        else
            rm -rf "$copy_to_before_commit/*"
        fi

        # Check if .gitignore file exists
        if [ -f "$directory_path/.gitignore" ]; then
            rsync -av --exclude-from="$directory_path/.gitignore" "$directory_path/" "$copy_to_before_commit"
            echo "Files copied successfully to $copy_to_before_commit."
        else
            rsync -av "$directory_path/" "$copy_to_before_commit"
            echo "Files copied successfully to $copy_to_before_commit."
        fi
    else
        echo "Invalid directory. Please enter a valid directory path."
        exit 1
    fi
}

# Function to initialize git repository
git_init0() {
    # Check if git_init is true
    if [ $git_init == true ]; then
        # Check if copy_to_before_commit is not false
        if [ $copy_to_before_commit != false ]; then
            # If the directory doesn't exist, create it
            if [ ! -d "$copy_to_before_commit" ]; then
                mkdir -p "$copy_to_before_commit"
            fi

            # Change directory to copy_to_before_commit
            cd $copy_to_before_commit
            rm -rf ".git" # Remove existing git repository if any
            git init
        fi
    fi
}


# Function to apply default settings
apply_defaults() {
    local working_directory=""
    local new_new_git_init=""

    if [ ! -d "$copy_to_before_commit" ]; then
        mkdir -p "$copy_to_before_commit"
    fi

    # Set working directory based on copy_to_before_commit variable
    if [ $copy_to_before_commit != false ]; then
        working_directory=$copy_to_before_commit
    else
        working_directory=$directory_path
    fi

    # Change directory to working_directory
    cd $working_directory

    # Check if git is initialized
    if [ $git_init != false ]; then
        :
    else
        # If git is not initialized, prompt user to initialize git
        if [ ! -d "./.git/" ]; then
            echo "git not initialised for this directory. Would you like to initialise git?"
            read -p "NOTE: You will lose all your past work if you push to an existing repository. Continue? (y/n): " new_git_init0
            if [ "${new_git_init0}" == "y" ]; then
                new_new_git_init="${new_git_init0}"
            else
                echo "git not initialised, exiting..."
                echo "You can enable 'git init' in the main menu"
                exit 1
            fi
        fi
    fi

    # Write configurations to ezcommit.config file in directory_path
    echo "github_repo=$github_repo" > $directory_path/ezcommit.config
    echo "branch=$branch" >> $directory_path/ezcommit.config
    echo "username=$username" >> $directory_path/ezcommit.config
    echo "git_init=$git_init" >> $directory_path/ezcommit.config
    echo "git_ignore=$git_ignore" >> $directory_path/ezcommit.config
    echo "copy_to_before_commit=$copy_to_before_commit" >> $directory_path/ezcommit.config

    echo $copy_to_before_commit
    echo $directory_path

    # If copy_to_before_commit is not false, copy files to the specified directory
    if [ $copy_to_before_commit != false ]; then
        copy_to_directory
    fi

    # If git_init is false, initialize git
    if [ $git_init != false ]; then
        rm -rf ".git"
        git init
    else
        # If git is not initialized and user has agreed to initialize it, initialize git
        if [ ! -d "$working_directory/.git/" ]; then
            if [ "${new_new_git_init}" == "y" ]; then
                rm -rf ".git"
                git init
            fi
        fi
    fi

    # Add, commit, and push changes to the remote repository
    git add .
    git commit -m comment
    git remote add origin $github_repo
    git push -u origin $branch --force

    # Write configurations to ezcommit.config file in working_directory
    echo "github_repo=$github_repo" > $working_directory/ezcommit.config
    echo "branch=$branch" >> $working_directory/ezcommit.config
    echo "username=$username" >> $working_directory/ezcommit.config
    echo "git_init=$git_init" >> $working_directory/ezcommit.config
    echo "git_ignore=$git_ignore" >> $working_directory/ezcommit.config
    echo "copy_to_before_commit=$copy_to_before_commit" >> $working_directory/ezcommit.config
}


# Define variables
github_repo="https://github.com/$username/$repo_name"
branch="master"
username="$username"
git_init=false

# Check if git is initialized
git_init=$(check_gitinit)

# Check if .gitignore file exists
git_ignore=$(check_gitignore)

# Set default values
copy_to_before_commit=false

# Define main menu function
main_menu() {
    
    # Check if ezcommit.config file exists in either directory_path or working_directory
    if [ -f "$directory_path/ezcommit.config" ]; then
        source $directory_path/ezcommit.config
    elif [ -f "$working_directory/ezcommit.config" ]; then
        source $working_directory/ezcommit.config
    else
        # If ezcommit.config file does not exist, set default values
        github_repo=$github_repo
        branch=$branch
        username=$username
        git_init=$git_init
        git_init=$git_init
        git_ignore=$git_ignore
        copy_to_before_commit=$copy_to_before_commit
    fi

    # Print GitHub Repo and menu
    echo ""
    echo ""
    echo -e "GitHub Repo=> ${GREEN}$github_repo${NC}"
    print_menu true
    echo -e "${NC}"
    read -p "continue? (y/n): " make_changes

    # If user chooses to make changes
    if [ "${make_changes}" == "y" ]; then
        apply_defaults
    else
        # If user chooses not to make changes, edit defaults
        edit_defaults
    fi
}

# Call main_menu function
main_menu