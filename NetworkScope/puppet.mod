# This mod gathers information from the 'facter' facts gathered about your hosts and adds it to the table

# You must call the: "getArrayLevel ${RESULT_IP} ${DATAPATH}" function each time you add a new column of data
# This is that the script knows where to place the data in the array

# After that, you can then add data, the ${BOTTOMPLUS1} variable adds 1 to the last array number [0][1][3] --> [0][1][4]
# echo "RESULT[${TOP}][${MIDDLE}][${BOTTOMPLUS1}]=\"Value";" >> data.sort.res

# Here we explicitly state we want the data to overwrite what is normally in the [x][x][3] array number
# In this example, we're getting the machine's hostname from a Puppet file rather than the result of the `host` command
# echo "RESULT[${TOP}][${MIDDLE}][3]=\"${PUPPET_FQDN}\";" >> data.sort.res


ENABLED=1
FACTDIR=/var/lib/puppet/yaml/facts
CERTDIR=/var/lib/puppet/ssl/ca/signed

if [[ "${ENABLED}" -eq 1 ]] ; then

NODE=$(grep -l "ipaddress: \"${RESULT_IP}\"" ${FACTDIR}/*)

  if [ ! -z "${NODE}" ]; then
    if test -f "${NODE}"; then
    CLIENTCERT=`cat "${NODE}" | grep -i clientcert: | awk {'print $2'} | cut -d\" -f2`

      if test -f ${CERTDIR}/$(echo ${CLIENTCERT}).pem; then
      PUPPET_FQDN=$(cat "{$NODE}" | grep -i fqdn: | awk {'print $2'} | cut -d\" -f2)
      PUPPET_OPERATINGSYSTEM=$(cat "${NODE}" | grep -i operatingsystem: | awk {'print $2'} | cut -d\" -f2)
      PUPPET_OPERATINGSYSTEMRELEASE=$(cat "${NODE}" | grep -i operatingsystemrelease: | awk {'print $2'} | cut -d\" -f2)
      PUPPET_ARCHITECTURE=$(cat "${NODE}" | grep -i architecture: | awk {'print $2'} | cut -d\" -f2)
      PUPPET_PHYSICALPROCESSORCOUNT=$(cat "${NODE}" | grep -i 'physicalprocessorcount:' | awk {'print $2'} | cut -d\" -f2)
      PUPPET_PROCESSORCOUNT=$(cat "${NODE}" | grep -i ' processorcount:' | awk {'print $2'} | cut -d\" -f2)
      PUPPET_VIRTUAL=$(cat "${NODE}" | grep -i ' virtual:' | awk {'print $2'} | cut -d\" -f2)

      getArrayLevel ${RESULT_IP} ${DATAPATH}
      echo "RESULT[${TOP}][${MIDDLE}][2]=\"${PUPPET_FQDN}\";" >> data.sort.res

      getArrayLevel ${RESULT_IP} ${DATAPATH}
      echo "RESULT[${TOP}][${MIDDLE}][${BOTTOMPLUS1}]=\"${PUPPET_OPERATINGSYSTEM}\";" >> data.sort.res

      getArrayLevel ${RESULT_IP} ${DATAPATH}
      echo "RESULT[${TOP}][${MIDDLE}][${BOTTOMPLUS1}]=\"${PUPPET_OPERATINGSYSTEMRELEASE}\";" >> data.sort.res

      getArrayLevel ${RESULT_IP} ${DATAPATH}
      echo "RESULT[${TOP}][${MIDDLE}][${BOTTOMPLUS1}]=\"${PUPPET_ARCHITECTURE}\";" >> data.sort.res

      getArrayLevel ${RESULT_IP} ${DATAPATH}
      echo "RESULT[${TOP}][${MIDDLE}][${BOTTOMPLUS1}]=\"${PUPPET_VIRTUAL}\";" >> data.sort.res

      getArrayLevel ${RESULT_IP} ${DATAPATH}
      for (( c=0; c<${PUPPET_PROCESSORCOUNT}; c++ ))
      do
        PUPPET_GETPROCESSOR=$(cat "${NODE}" | grep -i processor${c}: | cut -d":" -f2  | cut -d\" -f2)
        PUPPET_PROCESSORS="${PUPPET_PROCESSORS} <option>${c}: ${PUPPET_GETPROCESSOR}</option>"
      done
      echo "RESULT[${TOP}][${MIDDLE}][${BOTTOMPLUS1}]=\"<select><option>Processors - Physical: ${PUPPET_PHYSICALPROCESSORCOUNT}, Logical: ${PUPPET_PROCESSORCOUNT}</option>${PUPPET_PROCESSORS}</select>\";" >> data.sort.res
      unset PUPPET_PROCESSORS

      fi
    fi
  fi
fi
