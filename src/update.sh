#! /bin/bash

##### Constants

array=("$@")
NAME=${array[0]}
SCHE=${array[1]}
HOST=${array[2]}
# TODO Port is not used when connection is establised
PORT=${array[3]}
USER=${array[4]}
PASS=${array[5]}
LOCAL_PATH=${array[6]}
REMOTE_PATH=${array[7]}
# TODO This needs to be changed and passed through the array as well
# Add all ignore files here 
IGNORE_FILES=(
"FIRST_FILE_TO_BE_IGNORED"
"SECOND_FILE_TO_BE_IGNORED"
)

DIRECTORY_ARRAY=()
FILES_ARRAY=()

##### Functions

loop_trough_directories() {
  for dir in $1
    do
      if [ -d "$dir" ]; then
         echo -e "\e[0;34m Processing $dir directory..."
         for dir_loop in "$dir"*
          do
            check_for_ignored_files $dir_loop
            retval=$?
            if [ "$retval" == 0 ]; then
              echo  -e "\e[0;31m  Ignoring $dir_loop dir/file... "
            else 
              if [ -d "$dir_loop" ]; then
                check_if_directory_does_not_exist $dir_loop
                loop_trough_directories "$dir_loop"/
              fi
              if [ -f $dir_loop ]; then
                loop_through_file $dir_loop
              fi
            fi
          done
      fi
  done
}

loop_through_file() {
  for file in $1
    do
      if [ -f $file ]; then
        MODDATE=$(date -r $file +%F\ %T )
        remote_file=${file:${#LOCAL_PATH}:${#file}}
        echo -e "\t\033[32m Processing $remote_file file... "$MODDATE
        check_if_file_does_not_exist $remote_file
      fi
  done
}

check_if_file_does_not_exist() {
  file=$1
  if [ $(contains "${FILES_ARRAY[@]}" "$file") == "n" ]; then
    FILES_ARRAY=("${FILES_ARRAY[@]}" "$file")
  fi
}


check_for_ignored_files() { 
  for var in "${IGNORE_FILES[@]}"
    do
      if [[ "$LOCAL_PATH$var" == "$1" ]]; then
        return 0
      fi
  done
  return 1
}

check_if_directory_does_not_exist() {
  dir=$1
  directory=${dir:${#LOCAL_PATH}:${#dir}}

  if [ $(contains "${DIRECTORY_ARRAY[@]}" "$directory") == "n" ]; then
    DIRECTORY_ARRAY=("${DIRECTORY_ARRAY[@]}" "$directory")
  fi

}

contains() {
    local n=$#
    local value=${!n}
    for ((i=1;i < $#;i++)) {
        if [ "${!i}" == "${value}" ]; then
            echo "y"
            return 0
        fi
    }
    echo "n"
    return 1
}

connect_to_ftp_and_create_directories() { 
ftp -inv $HOST <<EOF
  user $USER $PASS
  $(create_directories)
  quit
EOF
}

create_directories() {
  for directory in "${DIRECTORY_ARRAY[@]}" 
    do
      #echo "status" 
      last_part=${directory##*/}
      IFS='/' read -a array <<< "$directory"
      arraysize=${#array[@]}
      dir_to_create=${array[$arraysize-1]}
      COUNTER=1
      for dir in "${array[@]}"
        do
          if [ "$COUNTER" == "$arraysize" ]; then
            echo "mkdir ${array[${#array[@]}-1]}"
          else
            echo "cd $dir"
          fi
          COUNTER=$(expr $COUNTER + 1)
        done
      echo "cd /"
  done
}

connect_to_ftp_and_upload_files() {
ftp -inv $HOST <<EOF
  user $USER $PASS
  $(upload_files)
  quit
EOF
}

upload_files() { 
  for file in "${FILES_ARRAY[@]}"
    do
      echo "put $LOCAL_PATH$file $file"
  done
}


##### Main
T="$(date +%s)"

loop_trough_directories $LOCAL_PATH
loop_time="$(($(date +%s)-T))"

#echo ${DIRECTORY_ARRAY[@]}
connect_to_ftp_and_create_directories
create_directories="$(($(date +%s)-T))"

connect_to_ftp_and_upload_files
upload_files="$(($(date +%s)-T))"

echo ;

echo "Execution time"

printf "Collecting information: %02d:%02d:%02d\n" "$(($loop_time/3600%24))" "$(($loop_time/60%60))" "$(($loop_time%60))"
printf "Creating directories  : %02d:%02d:%02d\n" "$((create_directories/3600%24))" "$((create_directories/60%60))" "$((create_directories%60))"
printf "Uploading files       : %02d:%02d:%02d\n" "$((upload_files/3600%24))" "$((upload_files/60%60))" "$((upload_files%60))"
