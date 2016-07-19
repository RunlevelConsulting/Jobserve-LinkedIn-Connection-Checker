#!/bin/bash

#############################################################################################
#											    #
# Author:  Daniel Hughes                                                                    #
# Company: Runlevel Consulting Ltd.                                                         #
# Website: runlevelconsulting.co.uk                                                         #
#                                                                                           #
# Purpose: Network Scope runs a scan against a network range of your choice and gather that #
#	   data into a nifty webpage or a single data file. Furthermore, it's modular so    #
#	   you can create custom modules to add more data to the output.		    #
#											    #
#############################################################################################

#########################################
## Custom Setup		               ##
#########################################

# Optional hard-coded values
#IPRANGES[0]="192.168.1.0/30"	# Can be a single IP, or a range (hyphen or CIDR)
#IPRANGES[1]="192.168.2.0/24"
#IPRANGES[2]="192.168.3.0/24"

CREATEWEBPAGE=1 		# Do you actually want to generate a webpage or just use the data?
WEBPATH=./index.html		# The full path of the page you want the data output to
SCANTYPE="common"		# common (100 Ports) / most (1000 ports) / all (all the things) / specific (scan certain ports)
PORTSTOSCAN=""			# (Only if SCANTYPE=specific). Format: 22,80,443-450 | Would scan ports 22, 80, and 443-450. NO SPACES!
SPEED=4				# Scan Speed: 1 (Slowest), 5 (Fastest)
USEMODULES=0			# Set this value to 1 to use custom modules (foo.mod)
DEBUG=0				# Debug Mode - Setting this value to 1 will stop the data files being deleted



#########################################
## Variables and Argument Handling     ##
#########################################
INSTRUCTIONS="\nUsage:   ./networkscope.sh --ip-ranges=192.168.1.0/24,192.168.2/24,10.10.10.10\n\nMandatory Flags:\n         --ip-ranges=                   Comma-separated list of IP ranges to scan\n\n	 Can be a single IP:		192.168.1.45\n	 Can be a CIDR range:		192.168.1.0/24\n	 Can be a from/to range:	192.168.1.0-10\n\n\nOptional Flags:\n         --dont-create-webpage			Do not construct an HTML webpage\n         --webpage-path=/path/to/page.html	Path to file in which to construct webpage\n         --scan-type=				Port scan depth (common, most, all, specific)\n         --scan-ports=				Specific ports to scan\n         --scan-speed=				Scan Speed: 1 (Slowest), 5 (Fastest)\n         --use-modules				Enable custom modules\n         --debug				Don't delete data files upon completion\n         -?					Show Instructions\n         --help					Show Instructions\n\n"
MESSAGE="\nThanks for using Network Scope!\nNmap can typically take a few seconds to scan a single host, bring snacks and entertainment if scanning a large range of IP's.\nNmap's OS detection is, on occasion, completely incorrect. You may want to enable Debug Mode to analyse the data more closely.\n\nContribute to this code at: https://github.com/RunlevelConsulting\n\n--------------------------------------------\n"
FINISHED="\n----------------- Finished -----------------\n\n"
SCRIPTPATH=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
DATAPATH="${SCRIPTPATH}/data.sort.res"
CURRENTTIME=$(date)


# Optional Command Line Flags & Arguments
while [[ $# -gt 0 ]] && [[ ."${1}" = .-* ]] ;
do
  opt=$(echo "${1}" | sed "s|~|$HOME|g")
  shift;
  case "${opt}" in
    "--" ) break 2;;
    "--ip-ranges="* )			IPRANGES=($(echo "${opt#*=}" | sed 's/,/ /g'));;
    "--dont-create-webpage" )		CREATEWEBPAGE=0;;
    "--webpage-path="* )    		WEBPATH="${opt#*=}";;
    "--scan-type="* )			SCANTYPE="${opt#*=}";;
    "--scan-ports="* )			PORTSTOSCAN="${opt#*=}";;
    "--scan-speed="* )			SPEED="${opt#*=}";;
    "--use-modules" )			USEMODULES=1;;
    "--debug" )				DEBUG=1;;
    "--help | -?" )			echo -e "${INSTRUCTIONS}"; exit 1;;
    *)					echo -e "${INSTRUCTIONS}"; exit 1;;
  esac
done
case "${SCANTYPE}" in
  common)       SCANTYPE_CONV="-F" ;;
  most)         SCANTYPE_CONV="" ;;
  all)          SCANTYPE_CONV="-p 0-65535" ;;
  specific)     SCANTYPE_CONV="-p ${PORTSTOSCAN}" ;;
  *)            SCANTYPE_CONV="-F" ;;
esac



#########################################
## Validation		               ##
#########################################

echo -e "${MESSAGE}"

if [ "${EUID}" -ne 0 ]; then
  echo -e "Error: This script must be run as root or with sudo.\n${FINISHED}"; exit 1;
fi

if [ ! -x "$(command -v nmap)" ]; then
  echo -e "Error: Nmap not installed.\n${FINISHED}"; exit 1;
fi

if [ -z "${IPRANGES}" ]; then
  echo -e "Error: No IP Ranges specified! Use the --help flag for instructions.\n${FINISHED}"; exit 1;
fi

if [ "${CREATEWEBPAGE}" -eq 0 ] && [ "${DEBUG}" -eq 0 ]; then
  echo -e "Warning: No webpage will be created and Debug Mode is disabled. This script will not save or output data.\n";
fi

if [ "${SPEED}" -lt 1 ] && [ "${SPEED}" -gt 5 ]; then
  echo -e "Error: Invald scan speed. Number should be between 1 and 5. Use the --help flag for instructions.\n${FINISHED}"; exit 1;
fi

if [ -z "${PORTSTOSCAN}" ] && [ "${SCANTYPE}" == "specific" ]; then
  echo -e "Error: The --scan-ports flag must be used when --scan-type is set to 'specific'. Use the --help flag for instructions.\n${FINISHED}"; exit 1;
fi


#########################################
## Functions		               ##
#########################################

getArrayLevel () {
  LINE=$(grep $1 $2)
  TOP=$(echo ${LINE} | awk 'NR>1{print $1}' RS=[ FS=] | sed -n 1p)
  MIDDLE=$(echo ${LINE} | awk 'NR>1{print $1}' RS=[ FS=] | sed -n 2p)
  BOTTOM=$(echo ${LINE} | awk 'NR>1{print $1}' RS=[ FS=] | sed -n 3p)
  GRABBOTTOM=$(grep "\$RESULT\[$TOP\]\[$MIDDLE\]" $2 | sort | tail -n1 | awk 'NR>1{print $1}' RS=[ FS=] | sed -n 3p)
  BOTTOMPLUS1=$((GRABBOTTOM+1))
}


scanSummary () {

  SUMM_IPRANGES=$(echo ${IPRANGES[@]} | sed 's/ /\n                        /g')
  [ "${CREATEWEBPAGE}" -eq 0 ] && 	SUMM_CREATEWEBPAGE="No" WEBPATH="N/A" || SUMM_CREATEWEBPAGE="Yes"
  [ "${USEMODULES}" -eq 0 ] && 		SUMM_USEMODULES="No" || SUMM_USEMODULES="Yes"
  [ "${DEBUG}" -eq 0 ] && 		SUMM_DEBUG="No" || SUMM_DEBUG="Yes"
  [ "${SCANTYPE}" != "specific" ] && 	PORTSTOSCAN="N/A"


  echo "  IP Range(s):		${SUMM_IPRANGES}
  Create Webpage:	${SUMM_CREATEWEBPAGE}
  Webpage Path:		${WEBPATH}
  Scan Type:		${SCANTYPE^} Ports
  Scan Ports:		${PORTSTOSCAN}
  Scan Speed:		${SPEED} out of 5
  Modules Enabled:	${SUMM_USEMODULES}
  Debug Mode:		${SUMM_DEBUG}

--------------------------------------------
"

}


########################################################################################################
########################################################################################################
## Begin gruntwork of running nmap & analysing nmap data - you shouldn't need to edit below this line ##
########################################################################################################
########################################################################################################
rm -f ${DATAPATH} *.nmap	# Delete everything from a previous run
scanSummary

IPCOUNT=0
for IPRANGE in "${IPRANGES[@]}"; do
  echo "RESULT[${IPCOUNT}] = new Array();" >> ${DATAPATH}

  #########################################
  ## Run the nmap scan			 ##
  #########################################
  echo "Scanning: ${IPRANGE}"
  nmap -sS -T${SPEED} -R –randomize-hosts –osscan-guess --max-os-tries 1 --log-errors -O ${SCANTYPE_CONV} ${IPRANGE} >> ${SCRIPTPATH}/ipRange${IPCOUNT}.nmap 2> /dev/null
  if [ "$?" -ne 0 ];then echo -e "Error: One of your IP Ranges was invalid.\n"; exit 1; fi

  #########################################
  ## Cut each result into it's own block ##
  #########################################
  i=1; s=1;
  declare -a arr;
  while read -r line; do
    [[ ${line} == "" ]] && ((i++)) && s=1 && continue
    [[ ${s} == 0 ]] && arr[${i}]=$(echo -e "${arr[$i]}\n$line") || { arr[${i}]=${line}; s=0; }
  done < ${SCRIPTPATH}/ipRange${IPCOUNT}.nmap

  #########################################
  ## For each block of nmap result...	 ##
  #########################################
  ENTRYCOUNT=0
  for i in "${arr[@]}"; do

    if [[ $(echo -e "$i" | wc -l) -gt 3 ]]; then

      #########################################
      ## Extract the slices of data needed   ##
      #########################################
      RESULT_IP=$(echo -e "${i}" | grep -v '^#' | grep -v Warning | grep -m 1 -oE '((1?[0-9][0-9]?|2[0-4][0-9]|25[0-5])\.){3}(1?[0-9][0-9]?|2[0-4][0-9]|25[0-5])')
      RESULT_MAC=$(echo -e "${i}" | grep -i "MAC\ Address" | awk {'print $3'})
      RESULT_HOSTNAME=$(host ${RESULT_IP} | tail -n1 | awk '{ print $NF }' | sed 's/.$//')

      # Sed: [0] Remove (XX%), [1] Remove anything after ' - ', [2] Remove anything after ' or '., [3] Every word uppercase
      RESULT_OS=$(echo "${i}" | grep "Aggressive" | cut -d ":" -f2 | cut -d "," -f1 | sed -e 's/([0-9][0-9]%)//g' -e 's/ - .*//g' -e 's/\ or .*//' -e 's/\b\(.\)/\u\1/g')
      if [[ -z "${RESULT_OS}" ]]; then
        # Sed: [0] Remove (XX%), [1] Every word uppercase
        RESULT_OS=$(echo "${i}" | grep "Running" | cut -d ":" -f2 | cut -d "," -f1 | cut -d "|" -f1 | sed -e 's/([0-9][0-9]%)//g' -e 's/ - .*//g' -e 's/\ or .*//' -e 's/\b\(.\)/\u\1/g')
      fi
      if [[ -z "${RESULT_OS}" ]]; then
        # Sed: [0] Remove anything after ' or ', [1] Remove any commas inside brackets
        RESULT_OS=$(echo "${i}" | grep "OS details:"  | cut -d ":" -f2 | sed  -e 's/\ or .*//' -e :1 -e 's/\(([^)]*\),/\1/g;t1' | cut -d "," -f1)
      fi

      IFS=$'\n'
      PORTS=$(echo "${i}" | grep ' open ' | grep -vi Warning)
	for line in $(echo "${PORTS}") ; do
        PORT_NUM=$(echo ${line} | cut -d "/" -f1)
        PORT_STATE=$(echo ${line} | awk {'print $2'})
        PORT_NAME=$(echo ${line} | awk 'NF>1{print $NF}')
	if [[ ${PORT_NUM} != "" ]]; then
          RESULT_PORTS="${RESULT_PORTS} <option>${PORT_NAME}(${PORT_NUM}) (${PORT_STATE})</option>"
        fi
      done

      if [[ "${RESULT_HOSTNAME}" == *NXDOMAIN* ]]; 	then	RESULT_HOSTNAME="";			fi
      if [[ -z "${RESULT_PORTS}" ]]; 			then	RESULT_PORTS="<option>None</option>";	fi
      if [[ -z "${RESULT_OS}" ]]; 			then	RESULT_OS="Unknown";	fi

      #########################################
      ## Output data to condensed data file  ##
      #########################################
      echo "RESULT[${IPCOUNT}][${ENTRYCOUNT}] = new Array();" >> ${DATAPATH}
      echo "RESULT[${IPCOUNT}][${ENTRYCOUNT}][0]=\"${RESULT_IP}\";" >> ${DATAPATH}
      echo "RESULT[${IPCOUNT}][${ENTRYCOUNT}][1]=\"${RESULT_MAC}\";" >> ${DATAPATH}
      echo "RESULT[${IPCOUNT}][${ENTRYCOUNT}][2]=\"${RESULT_OS}\";" >> ${DATAPATH}
      echo "RESULT[${IPCOUNT}][${ENTRYCOUNT}][3]=\"${RESULT_HOSTNAME}\";" >> ${DATAPATH}
      echo "RESULT[${IPCOUNT}][${ENTRYCOUNT}][4]=\"<select>${RESULT_PORTS}</select>\";" >> ${DATAPATH}
      unset RESULT_PORTS


      #########################################
      ## Run modules (.mod files)	     ##
      #########################################
      if [[ ${USEMODULES} -eq 1 ]]; then
        for file in ${SCRIPTPATH}/*.mod ; do
          if [ -f "${file}" ] ; then          source ${file};        fi
        done
      fi

    ((ENTRYCOUNT++))
    fi
  done

  #########################################
  ## Add IPRange and Count to data file	 ##
  #########################################
  echo "IPRANGE[${IPCOUNT}]=\"${IPRANGE}\";" >> ${DATAPATH}
  echo "ENTRYCOUNT[${IPCOUNT}]=\"${ENTRYCOUNT}\";" >> ${DATAPATH}
  unset arr
  ((IPCOUNT++))

done



#########################################
## Generate Webpage		       ##
#########################################
if [[ ${CREATEWEBPAGE} -eq 1 ]]; then
echo -e "\nGenerating Webpage: ${WEBPATH}"
cat > ${WEBPATH} <<- EOM
    <!DOCTYPE html>
    <html>
    <head>
    <title>Network Scope</title>
    <style>body {background-color: #E7F2FE; color: #222; font-family:Verdana, sans-serif; font-size:0.7em; margin:10px 5px 10px 5px; } select {font-family:Verdana, sans-serif; font-size:0.9em; margin:0;} a {font-weight:bold; color:#222; } .large {background-color: #E7F2FE; border:0; font-size: 22px; font-weight:bold; padding:20px 0px 4px 0px; text-align:center;} table {border-spacing: 0; margin-top:15px; width:100%;} td {padding:2px 5px 2px 5px;} .footer {text-align:center; margin:30px 0px 30px 0px;}tr:nth-child(even) {background: #c7e0f9;} tr:nth-child(odd) {background: #FFF}</style>
    <script>RESULT = new Array(); IPRANGE = new Array(); ENTRYCOUNT = new Array();function filterTable() {textfield = document.getElementById('filter').value.toLowerCase();d=document.getElementById('table').tBodies;for (i2 = 0; i2 < d.length; ++i2) {a=document.getElementById('table').tBodies[i2].rows;for (i = 0; i < a.length; ++i) {var tablerow=a[i].textContent.toLowerCase();if (textfield == ''){a[i].style.display="table-row";} else {if (document.getElementById("rev-filter").checked){a[i].style.display = tablerow.indexOf(textfield) !=-1 ? 'none' : 'table-row';} else {a[i].style.display = tablerow.indexOf(textfield) !=-1 ? 'table-row' : 'none';}}}}}
EOM
    cat ${DATAPATH} >> ${WEBPATH}
cat >> ${WEBPATH} <<- EOM
    </script>
    </head>
    <body>
    <h1>Network Scope</h1><input type="search" onFocus="filterTable();" onBlur="filterTable();" onKeyDown="filterTable();" onKeyUp="filterTable();" id="filter" placeholder="Filter"><label><input type="checkbox" onClick="filterTable();" id="rev-filter" value="1">Reverse Filter</label>
    <table id="table">
    <script>
    for ( i0=0; i0 < RESULT.length; i0++ ){			document.write("<thead><tr><td class=\"large\" colspan=\"100%\">" + IPRANGE[i0] + " - (" + ENTRYCOUNT[i0] + " Active Hosts)</td></tr></thead>");
      for ( i1=0; i1 < RESULT[i0].length; i1++ ){		document.write("<tr>");
        for ( i2=0; i2 < RESULT[i0][i1].length; i2++ ){		document.write("<td>" + RESULT[i0][i1][i2] + "</td>");
        }
      document.write("</tr>");
      }
    }
    </script>
    </table>
    <div class="footer"><strong>Last Run: </strong> ${CURRENTTIME}<br>Network Scope created by: <a href="http://runlevelconsulting.co.uk?r=networkscope" target="_blank">RunlevelConsulting.co.uk</a> | <a href="https://github.com/RunlevelConsulting" target="_blank">GitHub</a></div>
    </body>
    </html>
EOM
fi



#########################################
## Finish Up			       ##
#########################################
if [[ ${DEBUG} -eq 0 ]]; then  rm -f *.nmap ${DATAPATH};	fi
echo -e "${FINISHED}"
