#!/bin/bash

#############################################################################################
#											    #
# Author:  Daniel Hughes								    #
# Company: Runlevel Consulting Ltd.							    #
# Website: runlevelconsulting.co.uk							    #
# 											    #
# Purpose: This script gathers the name and contact details of all agents that have posted  #
#          jobs on JobServe.com. Can also show which of the agents you're Connected to on   #
#	   LinkedIn. Useful to gather contacts or jobs market data.			    #
#											    #
#############################################################################################



##########################################
## Options & Setup			##
##########################################

INSTRUCTIONS="\nUsage:   ./jobserve.sh --search-id=<SEARCH_ID>\n\nMandatory Flags:\n         --search-id=                   The Jobserve.com Search ID\n\n         You can find the SEARCH_ID by going to Jobserve.com, filling in your job search\n         criteria and hitting Search. The next URL will be:\n         https://www.jobserve.com/gb/en/JobSearch.aspx?shid=<SEARCH_ID>\n\nOptional Flags:\n         --li-file=/path/to/file.csv    Exorted LinkedIn Connections CSV file path\n         --only-connected               Only output jobs from LinkedIn connections\n         --only-unconnected             Only output jobs from LinkedIn strangers\n         --show-jobtitle                Show the Job Title of the posting\n         --show-company                 Show the name of the recruitment agency\n         --unique-names                 Supress multiple jobs from the same agent\n         --output-file=/path/to/file    Send all output to specified file\n         -?                             Show Instructions\n         --help                         Show Instructions\n\n         Export LinkedIn connections at: https://www.linkedin.com/people/export-settings\n"

MESSAGE="\nThanks for using the Jobserve-LinkedIn Connection Checker!\nPlease note that the script is dependent on response times from the Jobserve.com webservers.\nPlease also note that the connection-checker is by no means 100% accurate due to people having slightly different names on Jobserve and LinkedIn (e.g Joe vs Joseph).\n\nContribute to this code at: https://github.com/RunlevelConsulting"

# This cookie must be set in order to get a list of available jobs
# This generates a cookie in the same format Jobserve uses.
COOKIE=$(cat /dev/urandom | tr -dc 'A-F0-9' | fold -w 36 | head -n 1 | sed 's/./-/24' | sed 's/./-/19'| sed 's/./-/14' | sed 's/./-/9')


while [[ $# -gt 0 ]] && [[ ."${1}" = .-* ]] ;
do
    opt=$(echo "${1}" | sed "s|~|$HOME|g")
    shift;
    case "$opt" in
        "--" ) break 2;;
        "--search-id="* )
           SHID="${opt#*=}";;
        "--li-file="* )
           LI_FILE="${opt#*=}";;
        "--only-connected" )
           OC=1;;
        "--only-unconnected" )
           OU=1;;
        "--show-jobtitle" )
           SJ=1;;
        "--show-company" )
           SC=1;;
        "--unique-names" )
           UN=1;;
        "--output-file="* )
           OF="${opt#*=}";;
        "--help | -?" )
           echo -e "${INSTRUCTIONS}"; exit 1;;
        *)
           echo -e "${INSTRUCTIONS}"; exit 1;;
   esac
done



##########################################
## Validation				##
##########################################

# Validate Search ID
if [[ ! "${SHID}" =~ ^[A-F0-9]{18}$ ]]
then
    echo -e "\nError: Invalid --search-id\n       Do a search on jobserve.com and the URL will become similar to: https://www.jobserve.com/gb/en/JobSearch.aspx?shid=59A74C6FD4731B96CC\n       Grab the text after '?shid='.\n"
    exit 1
fi

# If it's specified to show both connections and unconnected, AKA: Show All
if [ "${OC}" ] && [ "${OU}" ]; then
  unset OC
  unset OU
fi

# If --only-connected or --only-unconnected is active but not --li-file path.
if [[ -z "${LI_FILE}" && ( "${OC}" || "${OU}" ) ]] ; then
  echo -e "\nError: In order to use --only-connected or --only-unconnected, you must use the --li-file flag.\n       Go to: https://www.linkedin.com/people/export-settings\n       Add the --li-file=/path/to/file.csv flag to the command.\n"
  exit 1
fi

# Check --output-file exists, if so, check perms, if not, try to create it
if [ "${OF}" ]; then
  if [ ! -f "${OF}" ]; then
  touch ${OF}
    if [ "$?" -ne 0 ]; then
      echo -e "\nError: Could not create file: ${OF}\n"
      exit 1
    fi
  else
    if [ ! -w "${OF}" ]; then
      echo -e "\nError: Write permissions not granted on file: ${OF}\n"
      exit 1
    fi
  fi
else
  OF="/dev/stdout"
fi

# Validate exported LinkedIn Connections file
if [ "${LI_FILE}" ]; then
  if [ ! -f "${LI_FILE}" ]; then
      echo -e "\nError: Could not find exported LinkedIn Connections file: ${LI_FILE}\n"
      exit 1
  else
    if [ ! "${LI_FILE: -3}" == "csv" ] && [ ! "${LI_FILE: -3}" == "CSV" ]; then
      echo -e "\nError: This doesn't look like a CSV file. Export a CSV from https://www.linkedin.com/people/export-settings\n"
      exit 1
    fi
  fi
fi



##########################################
## Function: getJobList			##
##########################################

function getJobList (){
  PAGENO=${1}

  # Curl the page
  JOBLISTDATA=$(curl --retry 5 -m 30 -s --cookie "JSFX=${COOKIE}" "https://www.jobserve.com/WebServices/JobSearch.asmx/RetrieveJobIds?resPage=${PAGENO}&shid=${SHID}&dateTo=d")

  # Extract the job IDs
  JOBLIST=$(echo "${JOBLISTDATA}" | grep -o -P '(?<=searchRes"&gt;).*(?=&lt;/div&gt;&lt;div class="searchResCount)')
  # Append to existing jobs list
  JOBLIST_ALL=$(echo "${JOBLIST}#${JOBLIST_ALL}")

  # We only get a maximum of 100 jobs displayed, this tells us how many more we have to go
  JOBSREMAINING=$(echo "${JOBLISTDATA}" | grep -o -P '(?<=searchResRemaining"&gt;).*(?=&lt;/div&gt;&lt;)')
  echo "Gathering Job IDs, ${JOBSREMAINING} remaining..."

    if [ "${JOBSREMAINING}" -gt 100 ]; then
      getJobList $((PAGENO+1))
    fi

}


##########################################
## Function: getJobDescriptions		##
##########################################

function getJobDescriptions (){
  # Make job list into an array
  JOBS_SEPARATED=$(echo "${1}" | sed 's/#/ /g' | sed 's/%/ /g' | xargs)
  JOBS_ARR=( ${JOBS_SEPARATED} )

  for JOBID in "${JOBS_ARR[@]}"
  do
    SUPRESS=0
    # Curl the Job Description Pag
    JOBDATA=$(curl --retry 3 -m 30 -s --cookie "JSFX=${COOKIE}" "https://www.jobserve.com/gb/en/mob/job/${JOBID}")
    # Extract Data
    PERMALINK=$(echo "${JOBDATA}" | awk '/Permalink/{getline; print}' | cut -d '"' -f2)
    TITLE=$(echo "${JOBDATA}" | grep -o '<h3>.*</h3>' | sed 's/\(<h3>\|<\/h3>\)//g' | tail -n1)
    TITLEWITHDIVIDER="  |  ${TITLE}"
    COMPANY=$(echo "${JOBDATA}" | grep -A1 '<label>Employment' | tail -n1 | sed "s/\&amp;/\&/g" | tr -cd "tr -cd '[[:alnum:]'" | sed -e 's/^[ \t]*//')
      if [ -z "${COMPANY}" ]; then COMPANY=$(echo "$JOBDATA" | grep -A1 '<label>Company</label>' | tail -n1 | sed "s/\&amp;/\&/g" | tr -cd "tr -cd '[[:alnum:]'" | sed -e 's/^[ \t]*//'); fi
    COMPANYWITHDIVIDER="  |  ${COMPANY}"
    CONTACT=$(echo "${JOBDATA}" | grep -A1 'Job_Contact' | tail -n1 | tr -cd "tr -cd '[[:alnum:]'" | sed -e 's/^[ \t]*//')
      if [ -z "${CONTACT}" ]; then CONTACT="Name Not Supplied"; fi

    # Supress un-unique contacts
    if [ "${UN}" ]; then
      if ! grep -q "'${CONTACT}'" <<< "${ALLCONTACTS}" ; then
        ALLCONTACTS="${ALLCONTACTS} '${CONTACT}'"
      else
        SUPRESS=1
      fi
    fi

    # Supress company name and job title if variables not declared
    if [ -z "${SC}" ]; then	unset COMPANYWITHDIVIDER;		fi
    if [ -z "${SJ}" ]; then	unset TITLEWITHDIVIDER;    		fi

    # If LinkedIn file undeclared supress connection status, else analyse
    if [ -z "${LI_FILE}" ]; then
      unset CONNECTIONSTATUSWITHDIVIDER;
    else
      CONTACT_FIRSTNAME=$(echo "${CONTACT}" | awk '{print $1}')
      CONTACT_SURNAME=$(echo "${CONTACT}" | awk 'NF>1{print $NF}')
        if [ -z "${CONTACT_SURNAME}" ]; then CONTACT_SURNAME=","; fi
      COMPANY_FIRSTNAME=$(echo "${COMPANY}" | egrep -o '[^ ]{3,}' | xargs | awk '{print $1}')

      READ_LI_FILE=$(cat "${LI_FILE}" | sed "s/'/\&#39;/g")
      CHECK1=$(echo "${READ_LI_FILE}" | grep -i ${CONTACT_FIRSTNAME} | grep -i ${CONTACT_SURNAME} | wc -l )
      CHECK2=$(echo "${READ_LI_FILE}" | grep -i ${CONTACT_FIRSTNAME} | grep -i ${CONTACT_SURNAME} | grep -i ${COMPANY_FIRSTNAME} | wc -l )

      if [ ${CHECK1} -eq 0 ]; then
        CONNECTIONSTATUS="[UNCONNECTED]"
      else
        if [ ${CHECK1} -eq 1 ]; then
          CONNECTIONSTATUS="[CONNECTED ✔]"
        else
          if [ ${CHECK2} -gt 1 ]; then
            CONNECTIONSTATUS="[CONNECTED ✔]"
          else
            CONNECTIONSTATUS="[UNCONNECTED]"
          fi
        fi
      fi
      CONNECTIONSTATUSWITHDIVIDER="  |  ${CONNECTIONSTATUS}"
    fi

    # And Output...
    if [ "${CONTACT}" ] && [ "${PERMALINK}" ] && [ "${SUPRESS}" -eq 0 ]; then
      if [[ ( -z "${OC}" && -z "${OU}" ) || ( "${OC}" == 1 && "${CONNECTIONSTATUS}" == "[CONNECTED ✔]" ) ||  ( "$OU" == 1 && "${CONNECTIONSTATUS}" == "[UNCONNECTED]" ) ]] ; then
        echo "${PERMALINK}${CONNECTIONSTATUSWITHDIVIDER}  |  ${CONTACT}${TITLEWITHDIVIDER}${COMPANYWITHDIVIDER}" | sed "s/\&#39;/'/g" | sed "s/\&amp;/\&/g"
      fi
    fi
  done

}



##########################################
## Put it all together...		##
##########################################

echo -e "${MESSAGE}"
echo -e "\n---------- Gathering Job List ---------" >> ${OF}
getJobList 1 >> ${OF}
echo -e "\n------------- Job Details -------------" >> ${OF}
getJobDescriptions ${JOBLIST_ALL} >> ${OF}
echo -e "\n--------------- Finished --------------\n"  >> ${OF}















##########################################
## Code Dump				##
##########################################

###################################################################################################################
# This is an alternative link to get Job Descriptions, however these are around 17KB vs the 8KB of the mobile site, this is not maintained so you may need to modify.
#
#    # Curl the Job Description Page
#    JOBDATA=$(curl --retry 3 -m 30 -s --cookie "JSFX=${COOKIE}" "https://www.jobserve.com/WebServices/JobSearch.asmx/RetrieveSingleJobDetail?id=${JOBID}" | sed 's/&lt;/</g' | sed 's/&gt;/>/g')
#    # Extract Data
#    PERMALINK=$(echo "$JOBDATA" | grep -o -P '(?<=md_permalink" target="_blank" class="jd_value">).*(?=</a>)')
#    TITLE=$(echo "$JOBDATA" | grep -o -P '(?<=itemprop="title" title=").*(?=" target)')
#    TITLEWITHDIVIDER="  |  ${TITLE}"
#    COMPANY=$(echo "$JOBDATA" | grep -o -P '(?<=itemprop="name">).*(?=</span></span>)')
#    COMPANYWITHDIVIDER="  |  ${COMPANY}"
#    if [[ "$JOBDATA" =~ "ShowContact()" ]]; then
#      CONTACT=$(echo "$JOBDATA" | grep -o -P '(?<=md_contact" class="jd_value">).*(?=&amp;nbsp;<)')
#    else
#      CONTACT=$(echo "$JOBDATA" | grep -o -P '(?<=md_contact" class="jd_value">).*(?=</span)')
#    fi
#
###################################################################################################################

