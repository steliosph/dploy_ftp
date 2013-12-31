#! /bin/bash

##### Constants

parameter_file=dploy
END="----next----"

while read line           
do
    parameter=${line##*:}
    command=${line%:*} 
    if [[ "name" == "$command" ]]; then
        PARAMETERS_ARRAY=($parameter);
    else
      if [[ "$END" == "$parameter" ]]; then
        ./update.sh ${PARAMETERS_ARRAY[@]}
      else
        PARAMETERS_ARRAY=("${PARAMETERS_ARRAY[@]}" "$parameter")
      fi
    fi
done <$parameter_file
