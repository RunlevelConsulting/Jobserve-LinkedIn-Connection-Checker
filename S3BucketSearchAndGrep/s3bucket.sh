#!/bin/bash

#############################################################################################
#											    #
# Author:  Daniel Hughes                                                                    #
# Company: Runlevel Consulting Ltd.                                                         #
# Website: runlevelconsulting.co.uk                                                         #
#                                                                                           #
# Purpose: Search and list the contents of public AWS S3 Buckets with the added ability to  #
#	   search for specific content within those files. This content is then output to   #
#	   a CSV file where data can be ordered and filtered further.			    #
#											    #
#############################################################################################



########################################################################################################################################
## Options & Setup														      ##
########################################################################################################################################

INSTRUCTIONS="\nUsage:     ./s3bucket.sh --url=http://mysite.s3.amazonaws.com --use-cache --grep\n\nMandatory Flags:\n	   --url=		The URL of the S3 Bucket\n\nOptional Flags:\n	   --grep		Search for string within files\n	   --use-cache		Use S3 Bucket list from a previous run (may not be up-to-date but will be much faster)\n           -?                   Show Instructions\n           --help               Show Instructions"
MESSAGE="\nThanks for using S3 Bucket Search n' Grep!\nDepending on how many files are in the bucket, you may be in for a wait.\n\nContribute to this code at: https://github.com/RunlevelConsulting\n\n--------------------------------------------\n"

while [[ $# -gt 0 ]] && [[ ."${1}" = .-* ]] ;
do
    opt=$(echo "${1}")
    shift;
    case "${opt}" in
        "--" ) break 2;;
        "--url="* )
           URL="${opt#*=}"
           URL=$(echo "${URL}" | sed 's/\/$//g');;
        "--grep" )
           GREP_FILES=1;;
        "--use-cache" )
           USE_CACHE=1;;
        "--help | -?" )
           echo -e "${INSTRUCTIONS}"; exit 1;;
        *)
           echo -e "${INSTRUCTIONS}"; exit 1;;
   esac
done

echo -e "${MESSAGE}"
URLSANITISED=$(echo "$URL" | tr A-Z a-z | sed -e 's/[^a-z0-9]//g' | sed 's/https\?:\/\///' | sed 's/\/$//g')
MAINCACHEFILE="result.${URLSANITISED}"









########################################################################################################################################
## Validation    												                      ##
########################################################################################################################################

# If S3 Bucket URL hasn't been specified
if [ -z "${URL}" ]; then
  echo -e "Error: No S3 Bucket URL specified! Use the --help flag for instructions.\n";
  exit 1;
fi

# If --use-cache is specified but cachefile doesn't exist
if [ "${USE_CACHE}" ]; then
  echo -e "Info: This script will use a cache file to generate top-level and subdirectory data if the respective cache files exist. Otherwise, it will download new data.\n"
fi

# Grab (what should be) a small version of the bucket
TESTURL=$(curl -s "${URL}/?max-keys=1")
# Is it a valid bucket?
if [[ ! "$TESTURL" =~ ^'<?xml'.*|'</ListBucketResult>'$ ]]; then
  echo -e "Error: This doesn't seem to be a valid S3 Bucket...? They normally begin with and XML tag and end with '</ListBucketResult>'\n"
  exit 1
fi

ARETHEREKEYS=$(echo "${TESTURL}" | grep -o '<Key>' | wc -l)
# Does it actually have anything in it?
if [[ "$ARETHEREKEYS" -eq 0 ]]; then
  echo -e "Error: This bucket appears to be empty! (No <Key> tags found)\n"
  exit 1
fi








########################################################################################################################################
## Functions		                                                                                                              ##
########################################################################################################################################


#################################################################################################
### Download Bucket										#
#												#
# In order to list beyond 1000 items in an S3 Bucket, you need to modify the URL parameters.	#
# This script loops through the bucket, modifying parameters as it goes until it reaches the	#
# end. All this output, including irrelevant data is dumped into a file for processing later.	#
#												#
#################################################################################################

downloadBucket(){
  MARKER=${1}
  DELIMITER=${2}
  PREFIX=${3}
  SUFFIX=${4}

  if [ "$PREFIX" ]; then
    MAINCACHEFILE="result.${URLSANITISED}.${PREFIX}"
  fi

  WEB=$(curl -s -G "${URL}/" -d "marker=${1}&delimiter=${DELIMITER}&prefix=${PREFIX}&suffix=${SUFFIX}")
  ISTRUNCATED=$(echo "$WEB" | grep -oPm1 "(?<=<IsTruncated>)[^<]+")
  KEYS=$(echo "$WEB" | grep -oPm1 "(?<=<Key>)[^<]+")
    if [ -z "${KEYS}" ]; then    KEYS=$(echo "$WEB" | grep -oPm1 "(?<=<Prefix>)[^<]+");  fi
  LASTKEY=$(echo "$KEYS" | tail -n1 | sed 's/ /\\\ /g')

  echo "${WEB}" >> ${MAINCACHEFILE}.full
  if [ "$ISTRUNCATED" == "true" ]; then
    downloadBucket "$LASTKEY" "${DELIMITER}" "${PREFIX}" "${SUFFIX}";
  fi
}



#################################################################################################
### Analyse Bucket										#
#												#
# We now gather the required data from the curl dump file by separating out and extracting the  #
# data. The data is then output to a CSV file which can then be a cache for future searches.	#
#												#
#################################################################################################


analyseBucket(){
  CREATEBLOCKS=$(cat ${1} | sed "s/<${2}>/\n<${2}>/g" | sed "s/<\/${2}>/<\/${2}>\n/g" | grep "<${2}>" | sed "s/<${2}>/\n<${2}>/g") # Not my finest hour, but it works...

  b=1
  s=1
  declare -a arr
  while read -r line; do
    [[ $line =~ ^# ]] && continue
    [[ $line == "" ]] && ((b++)) && s=1 && continue
    [[ $s == 0 ]] && arr[$b]="${arr[$b]}
$line" || {
      arr[$b]="$line"
      s=0;
    }
  done <<< "$CREATEBLOCKS"

  for i in "${arr[@]}"
  do
    # Create vars
    BLOCK=$(echo -E "$i")

    if [ "${2}" == "Contents" ]; then
      KEY=$(echo "$BLOCK" | grep -oPm1 "(?<=<Key>)[^<]+" | sed 's/,/%2C/g')
      SIZE=$(echo "$BLOCK" | grep -oPm1 "(?<=<Size>)[^<]+")
      LASTMODIFIED=$(echo "$BLOCK" | grep -oPm1 "(?<=<LastModified>)[^<]+")
    else
      KEY=$(echo "$BLOCK" | grep -oPm1 "(?<=<Prefix>)[^<]+")
    fi
    echo "${KEY},${SIZE},${LASTMODIFIED}" >> ${MAINCACHEFILE}.csv

    BLOCK=;KEY=;SIZE=;LASTMODIFIED=;
  done
  arr=;
}



#################################################################################################
### Output Choices										#
#												#
# We give the user a choice about which directories they want to gather file information on. If	#
# the root directory has files then also offer a '/' option.					#
#												#
#################################################################################################


function outputChoices(){
  GETDIRS=$(cat ${1} | grep ",," | cut -d "/" -f 1)
  COUNTDIRS=$(cat ${1} | grep ",," | cut -d "/" -f 1 | wc -l)
  COUNTFILES=$(cat ${1} | grep -v ",," | wc -l)
  ARRAY=()

  if [[ "$COUNTFILES" -gt 0 ]]; then
    ARRAY+=('/')
  fi
  if [[ "$COUNTDIRS" -gt 0 ]]; then
    while read -r line; do
      ARRAY+=("$line")
    done <<< "$GETDIRS"
  fi
  for i in "${!ARRAY[@]}"; do
    echo "[$i] ${ARRAY[$i]}"
  done

  echo -e "\n"
  read -p "Please input the NUMBER of the directory you wish to search: " DIRECTORYID
  DIRECTORY="${ARRAY[$DIRECTORYID]}"
}




#################################################################################################
### Grep Files											#
#												#
# If the user has specified the --grep option, analyse the file extensions within the 		#
# subdirectory and list them by no. of occurrences. Take input of what string the user wants to	#
# search for and what file extensions they want to search within. Then loop through each file	#
# searching each one for the string, output results to STDOUT and new CSV file.			#
#												#
#################################################################################################

function grepFiles(){

  echo -e "\nBelow is a list of file extensions and the number of occurrence of each extension in this directory:"
  cat "${1}" | cut -d "," -f1 | grep -v "/$"| grep -v ",," | rev | cut -d "/" -f1 | cut -d "." -f1 | rev | sort | uniq -c | sort -n # Truly magnificent...

  echo ""
  read -p "What string are you looking for? (e.g: password): " STRING
  read -p "Look for \"${STRING}\" in which file extensions? (comma-separated, eg: json, html, cfg): " FILTER
  echo -e "\nSearching..."


  FILTER=$(echo "${FILTER}" | sed -e 's/ //g' -e 's/,/|/g')
  FILTEREDFILES=$(cat "${1}" | cut -d "," -f1 | grep -v "/$"| grep -v ",," | egrep "(${FILTER})$")
  COUNTFILTEREDFILES=$(echo "${FILTEREDFILES}" | wc -l)

  MAINCACHEFILE="${MAINCACHEFILE}.search"
  >${MAINCACHEFILE}

  while read -r line; do
  ((COUNTER++))

  CURLOUT=$(curl --compressed -s "${URL}/${line}")
  [[ $CURLOUT == *"${STRING}"* ]] && ICON="✔" || ICON="✘"
  echo "${URL}/${line},${ICON}" >> ${MAINCACHEFILE}.csv
  echo "[${COUNTER}/${COUNTFILTEREDFILES}] ${ICON}  ${URL}/${line}"
  done <<< "$FILTEREDFILES"

}

















########################################################################################################################################
## Start Running Stuff   												              ##
########################################################################################################################################

# Top-Level Stuff
if [ -z "${USE_CACHE}" ] || [ ! -f "${MAINCACHEFILE}.csv" ]; then
  >${MAINCACHEFILE}.csv
  >${MAINCACHEFILE}.full
  echo "Gathering Top-Level Contents..."
  downloadBucket "" "/" "" ""
  echo "Analysing Top-Level Contents..."
  analyseBucket "${MAINCACHEFILE}.full" "Contents"
  analyseBucket "${MAINCACHEFILE}.full" "CommonPrefixes"
  echo -e "\n--------------------------------------------\n"
fi

# Output Directory List
outputChoices "${MAINCACHEFILE}.csv"

# Direcory chosen, now analyse subdirectory
if [[ "$DIRECTORY" != "/" ]]; then
  MAINCACHEFILE="${MAINCACHEFILE}.${DIRECTORY}"
  if [ -z "${USE_CACHE}" ] || [ ! -f "${MAINCACHEFILE}.csv" ]; then
    echo -e "\n--------------------------------------------\n"
    echo "Gathering ${DIRECTORY} Contents..."
    downloadBucket "" "" "${DIRECTORY}" ""
    echo "Analysing ${DIRECTORY} Contents..."
    analyseBucket "${MAINCACHEFILE}.full" "Contents"
    analyseBucket "${MAINCACHEFILE}.full" "CommonPrefixes"
  fi
else
  sed "/,,$/d" ${MAINCACHEFILE}.csv > ${MAINCACHEFILE}.root.csv
  MAINCACHEFILE="${MAINCACHEFILE}.root"
fi

# Did user want to do a full grep?
if [ "${GREP_FILES}" ]; then
  echo -e "\n--------------------------------------------\n"
  grepFiles "${MAINCACHEFILE}.csv"
fi

# Finish it
echo -e "\n--------------------------------------------\n"
echo "Output: ${MAINCACHEFILE}.csv"
echo -e "\n--------------------------------------------\n"
rm *.full 2> /dev/null

