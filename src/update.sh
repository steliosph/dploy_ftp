#! /bin/bash

##### Constants

array=("$@")
NAME=${array[0]}
SCHE=${array[1]}
HOST=${array[2]}
PORT=${array[3]}
USER=${array[4]}
PASS=${array[5]}
LOCAL_PATH=${array[6]}
REMOTE_PATH=${array[7]}
SAVE_TIMES_TO_FILE=${array[8]}
LOCAL_FILE="dates"
LOCAL_DIR="directories"
# TODO This needs to be changed and passed through the array as well 
IGNORE_FILES=(
"file.php" 
"src/directory" 
)

#Hidden files of files or files that are in a ignored folder. NOT YET WORKING
INCLUDE_FILES=(
".htacess"
)

DIRECTORY_ARRAY=()
FILES_ARRAY=()
LOCAL_FILE_CONTENT=()
LOCAL_FILE_CONTENT_TO_BE_COMPARED=()
LOCAL_DIR_CONTENT=()
LOCAL_FIR_CONTENT_TO_BE_COMPARED=()

##### Functions

loop_trough_directories() {
  for dir in $1
    do
      if [ -d "$dir" ]; then
         #echo -e "\e[0;34m Processing $dir directory..."
         LOCAL_DIR_CONTENT=("${LOCAL_DIR_CONTENT[@]}" "$dir")

         for dir_loop in "$dir"*
          do
            check_for_ignored_files $dir_loop
            retval=$?
            if [ "$retval" == 1 ]; then
              if [ -d "$dir_loop" ]; then
                check_if_directory_does_not_exist $dir_loop
                loop_trough_directories "$dir_loop"/
              fi
              if [ -f $dir_loop ]; then
                loop_through_file $dir_loop
              fi
           # else
               #echo  -e "\e[0;31m  Ignoring $dir_loop dir/file... "
 
            fi
          done
      fi
  done
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

  contains "${DIRECTORY_ARRAY[@]}" "$directory"
  retval=$?
  if [ "$retval" == 1 ]; then
    DIRECTORY_ARRAY=("${DIRECTORY_ARRAY[@]}" "$directory")
  fi
}

contains() {
    local n=$#
    local value=${!n}
    for ((i=1;i < $#;i++)) {
        if [ "${!i}" == "${value}" ]; then
            return 0
        fi
    }
    return 1
}

loop_through_file() {
  for file in $1
    do
      if [ -f $file ]; then
        MODDATE=$(date -r $file +%F\ %T )
        remote_file=${file:${#LOCAL_PATH}:${#file}}
        time_created="$LOCAL_PATH$remote_file : $MODDATE"
        LOCAL_FILE_CONTENT=("${LOCAL_FILE_CONTENT[@]}" "$time_created")
        check_if_file_does_not_exist $remote_file
      fi
  done
}

check_if_file_does_not_exist() {
  file=$1
  contains "${FILES_ARRAY[@]}" "$file"
  retval=$?

  if [ $retval == 0 ]; then
    FILES_ARRAY=("${FILES_ARRAY[@]}" "$file")
  fi
}

## Read Files for directories
read_file_for_directories () {
  if [ -f "$LOCAL_DIR" ]; then
    IFS=$'\r\n' LOCAL_DIR_CONTENT_TO_BE_COMPARED=($(cat $LOCAL_DIR))
  fi
}

connect_to_ftp_and_create_directories() { 
ftp -inv $HOST <<EOF
  user $USER $PASS
  cd $REMOTE_PATH
  $(create_directories)
  quit
EOF
}

create_directories() {
  for directory in "${DIRECTORY_ARRAY[@]}" 
    do
      is_directory_already_created "$directory"
      retval=$?
    
      if [ "$retval" == 1 ];then
        continue
      fi
      last_part=${directory##*/}
      IFS='/' read -a array <<< "$directory"
      arraysize=${#array[@]}
      dir_to_create=${array[$arraysize-1]}
      COUNTER=1
      for dir in "${array[@]}"
        do
          if [ "$COUNTER" == "$arraysize" ]; then
            echo "mkdir ${array[${#array[@]}-1]}"
            break
          else
            echo "cd $dir"
          fi
          COUNTER=$(expr $COUNTER + 1)
        done
      echo "cd /"
      echo "cd $REMOTE_PATH"
  done
}

is_directory_already_created () {
  for directory in "${LOCAL_DIR_CONTENT_TO_BE_COMPARED[@]}"
  do
    if [ "$LOCAL_PATH$1/" == "$directory" ];then
      return 1
    fi
  done
  return 0
}

read_file_for_date () {
  if [ -f "$LOCAL_FILE" ]; then
    IFS=$'\r\n' LOCAL_FILE_CONTENT_TO_BE_COMPARED=($(cat $LOCAL_FILE))
  fi
}

connect_to_ftp_and_upload_files() {
ftp -inv $HOST <<EOF
  user $USER $PASS
  cd $REMOTE_PATH
  $(upload_files)
  quit
EOF
}

upload_files() { 
  for file in "${FILES_ARRAY[@]}"
    do
      file_not_found="true"
      for file_date in "${LOCAL_FILE_CONTENT_TO_BE_COMPARED[@]}"
      do
        date_part=${file_date##*: }
        file_part=${file_date% :*}
        if [ "$file_part" == "$LOCAL_PATH$file" ]; then
            file_not_found="false"
            mod_date=$(date -r $LOCAL_PATH$file +%F\ %T )
            mod_date_sec=$(date -d "$mod_date" +%s )
            date_part_sec=$(date -d "$date_part" +%s)
            if (("$date_part_sec" < "$mod_date_sec")); then
              echo "put $LOCAL_PATH$file $file"
              break;
            fi
        fi
      done
      if [ $file_not_found == "true" ]; then
        echo "put  $LOCAL_PATH$file $file"
      fi
  done
}

write_to_file () { 
  #echo "Writing last edited dates to file"
  if [ ! -f "$LOCAL_FILE" ] ; then
    # Check if file exists if not create the file
    touch "$LOCAL_FILE"
  else
    > "$LOCAL_FILE"
  fi
  for line in "${LOCAL_FILE_CONTENT[@]}"
  do
    echo $line
  done >> "$LOCAL_FILE"
}

write_to_directories () { 
  #echo "Writing last edited directories to file"
  if [ ! -f "$LOCAL_DIR" ] ; then
    # Check if file exists if not create the file
    touch "$LOCAL_DIR"
  else
    > "$LOCAL_DIR"
  fi
  for line in "${LOCAL_DIR_CONTENT[@]}"
  do
    echo $line
  done >> "$LOCAL_DIR"
}

##### Main
T="$(date +%s)"

echo -e "\033[1;33;44m--------------------------------------------------\033[0m"
echo -e "\033[1;33;44m----------- RUNNING THROUGH DIRECTORIES ----------\033[0m"
echo -e "\033[1;33;44m--------------------------------------------------\033[0m"

loop_trough_directories $LOCAL_PATH
loop_time="$(($(date +%s)-T))"

echo -e "\033[1;33;44m--------------------------------------------------\033[0m"
echo -e "\033[1;33;44m-------- CREATING NON EXISTING DIRECTORIES -------\033[0m"
echo -e "\033[1;33;44m--------------------------------------------------\033[0m"

read_file_for_directories
connect_to_ftp_and_create_directories
create_directories="$(($(date +%s)-T))"

echo -e "\033[1;33;44m--------------------------------------------------\033[0m"
echo -e "\033[1;33;44m---------- UPLOADING & OVERWRITING FILES ---------\033[0m"
echo -e "\033[1;33;44m--------------------------------------------------\033[0m"

read_file_for_date
connect_to_ftp_and_upload_files
upload_files="$(($(date +%s)-T))"

echo -e "\033[1;33;44m--------------------------------------------------\033[0m"
echo -e "\033[1;33;44m------------ WRITING TO EXISTING FILES -----------\033[0m"
echo -e "\033[1;33;44m--------------------------------------------------\033[0m"

if [ $SAVE_TIMES_TO_FILE == "true" ]; then
  write_to_file
  write_to_directories
fi
echo ;

echo "Execution time"

printf "Collecting information: %02d:%02d:%02d\n" "$(($loop_time/3600%24))" "$(($loop_time/60%60))" "$(($loop_time%60))"
printf "Creating directories  : %02d:%02d:%02d\n" "$((create_directories/3600%24))" "$((create_directories/60%60))" "$((create_directories%60))"
printf "Uploading files       : %02d:%02d:%02d\n" "$((upload_files/3600%24))" "$((upload_files/60%60))" "$((upload_files%60))"
