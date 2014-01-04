#! /bin/bash

##### Constants

parameter_file=dploy
EXECUTE="----NEXT----"
END="----END----"

while read line           
do
    parameter=${line##*:}
    if [[ "$END" == "$parameter" ]]; then
         ./update.sh ${PARAMETERS_ARRAY[@]}
        break
    fi
    command=${line%:*} 
    if [[ "name" == "$command" ]]; then
        PARAMETERS_ARRAY=($parameter);
    else
      if [[ "$EXECUTE" == "$parameter" ]]; then
        ./update.sh ${PARAMETERS_ARRAY[@]}
      else
        PARAMETERS_ARRAY=("${PARAMETERS_ARRAY[@]}" "$parameter")
      fi
    fi
done <$parameter_file

