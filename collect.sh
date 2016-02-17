#!/bin/bash

INIZIO=$1
FINE=$2

# Set directory remote
DIR_LOG=/tmp/estrazione_log
DIR_LOG_DB=/tmp/estrazione_log2
LOG_FILE=\$HOSTNAME.batch.log

# TCL Expect
SSH=../sshex.tcl
SCP_FROM=../scpf.tcl

################################################################################################################
time_stamp(){
date +%b\ %d\ %H:%M:%S
}
################################################################################################################
extract(){

echo "$(time_stamp) --> Esecuzione su 10.207.149.38"
$SSH Password  was@10.207.149.38 "
export HOSTNAME=\$(hostname)
/home/was/bin/estrae_log.sh -c \"$INIZIO\" \"$FINE\"  >> $DIR_LOG/$LOG_FILE 2>&1
/home/was/bin/estrae_log.sh -e \"$INIZIO\" \"$FINE\"  >> $DIR_LOG/$LOG_FILE 2>&1
/home/was/bin/estrae_log.sh -s \"$INIZIO\" \"$FINE\"  >> $DIR_LOG/$LOG_FILE 2>&1
/home/was/bin/estrae_log.sh -P \"$INIZIO\" \"$FINE\"  >> $DIR_LOG/$LOG_FILE 2>&1
/home/was/bin/estrae_log.sh -j \"$INIZIO\" \"$FINE\"  >> $DIR_LOG/$LOG_FILE 2>&1
/home/was/bin/estrae_log.sh -n \"$INIZIO\" \"$FINE\"  >> $DIR_LOG/$LOG_FILE 2>&1
/home/was/bin/estrae_log.sh -D \"$INIZIO\" \"$FINE\"  >> $DIR_LOG/$LOG_FILE 2>&1
/home/was/bin/estrae_log.sh -o \"$INIZIO\" \"$FINE\"  >> $DIR_LOG/$LOG_FILE 2>&1 " > /dev/null 2>&1 &

echo "$(time_stamp) --> Esecuzione su 10.207.149.42"
$SSH Password  was@10.207.149.42 "
export HOSTNAME=\$(hostname)
/home/was/bin/estrae_log.sh -c \"$INIZIO\" \"$FINE\"  >> $DIR_LOG/$LOG_FILE 2>&1
/home/was/bin/estrae_log.sh -e \"$INIZIO\" \"$FINE\"  >> $DIR_LOG/$LOG_FILE 2>&1
/home/was/bin/estrae_log.sh -s \"$INIZIO\" \"$FINE\"  >> $DIR_LOG/$LOG_FILE 2>&1
/home/was/bin/estrae_log.sh -P \"$INIZIO\" \"$FINE\"  >> $DIR_LOG/$LOG_FILE 2>&1
/home/was/bin/estrae_log.sh -j \"$INIZIO\" \"$FINE\"  >> $DIR_LOG/$LOG_FILE 2>&1
/home/was/bin/estrae_log.sh -n \"$INIZIO\" \"$FINE\"  >> $DIR_LOG/$LOG_FILE 2>&1
/home/was/bin/estrae_log.sh -D \"$INIZIO\" \"$FINE\"  >> $DIR_LOG/$LOG_FILE 2>&1
/home/was/bin/estrae_log.sh -o \"$INIZIO\" \"$FINE\"  >> $DIR_LOG/$LOG_FILE 2>&1 " > /dev/null 2>&1 &

echo "$(time_stamp) --> Esecuzione su 10.207.213.100"
$SSH Password  was@10.207.213.100 "
export HOSTNAME=\$(hostname)
/home/was/bin/estrae_log.sh -c \"$INIZIO\" \"$FINE\"  >> $DIR_LOG/$LOG_FILE 2>&1
/home/was/bin/estrae_log.sh -a \"$INIZIO\" \"$FINE\"  >> $DIR_LOG/$LOG_FILE 2>&1
/home/was/bin/estrae_log.sh -o \"$INIZIO\" \"$FINE\"  >> $DIR_LOG/$LOG_FILE 2>&1
/home/was/bin/estrae_log.sh -t \"$INIZIO\" \"$FINE\"  >> $DIR_LOG/$LOG_FILE 2>&1  " > /dev/null 2>&1 &

echo "$(time_stamp) --> Esecuzione su 10.207.213.101"
$SSH Password  was@10.207.213.101 "
export HOSTNAME=\$(hostname)
/home/was/bin/estrae_log.sh -c \"$INIZIO\" \"$FINE\"  >> $DIR_LOG/$LOG_FILE 2>&1
/home/was/bin/estrae_log.sh -a \"$INIZIO\" \"$FINE\"  >> $DIR_LOG/$LOG_FILE 2>&1
/home/was/bin/estrae_log.sh -o \"$INIZIO\" \"$FINE\"  >> $DIR_LOG/$LOG_FILE 2>&1
/home/was/bin/estrae_log.sh -t \"$INIZIO\" \"$FINE\"  >> $DIR_LOG/$LOG_FILE 2>&1  " > /dev/null 2>&1 &

echo "$(time_stamp) --> Esecuzione su 10.207.213.102"
$SSH Password  was@10.207.213.102 "
export HOSTNAME=\$(hostname)
/home/was/bin/estrae_log.sh -c \"$INIZIO\" \"$FINE\"  >> $DIR_LOG/$LOG_FILE 2>&1
/home/was/bin/estrae_log.sh -a \"$INIZIO\" \"$FINE\"  >> $DIR_LOG/$LOG_FILE 2>&1
/home/was/bin/estrae_log.sh -o \"$INIZIO\" \"$FINE\"  >> $DIR_LOG/$LOG_FILE 2>&1
/home/was/bin/estrae_log.sh -t \"$INIZIO\" \"$FINE\"  >> $DIR_LOG/$LOG_FILE 2>&1  " > /dev/null 2>&1 &

echo "$(time_stamp) --> Esecuzione su 10.207.213.103"
$SSH Password  was@10.207.213.103 "
export HOSTNAME=\$(hostname)
/home/was/bin/estrae_log.sh -c \"$INIZIO\" \"$FINE\"  >> $DIR_LOG/$LOG_FILE 2>&1
/home/was/bin/estrae_log.sh -a \"$INIZIO\" \"$FINE\"  >> $DIR_LOG/$LOG_FILE 2>&1
/home/was/bin/estrae_log.sh -o \"$INIZIO\" \"$FINE\"  >> $DIR_LOG/$LOG_FILE 2>&1
/home/was/bin/estrae_log.sh -t \"$INIZIO\" \"$FINE\"  >> $DIR_LOG/$LOG_FILE 2>&1  " > /dev/null 2>&1 &

echo "$(time_stamp) --> Esecuzione su 10.207.213.105"
$SSH Password  was@10.207.213.105 "
export HOSTNAME=\$(hostname)
/home/was/bin/estrae_log.sh -c \"$INIZIO\" \"$FINE\"  >> $DIR_LOG/$LOG_FILE 2>&1
/home/was/bin/estrae_log.sh -a \"$INIZIO\" \"$FINE\"  >> $DIR_LOG/$LOG_FILE 2>&1
/home/was/bin/estrae_log.sh -o \"$INIZIO\" \"$FINE\"  >> $DIR_LOG/$LOG_FILE 2>&1
/home/was/bin/estrae_log.sh -t \"$INIZIO\" \"$FINE\"  >> $DIR_LOG/$LOG_FILE 2>&1  " > /dev/null 2>&1 &

echo "$(time_stamp) --> Esecuzione su 10.207.149.160"
$SSH Mon121Pr  usrmonit@10.207.149.160 "
export HOSTNAME=\$(hostname)
/home/usrmonit/bin/estrae_log.sh -c \"$INIZIO\" \"$FINE\"  >> $DIR_LOG/$LOG_FILE 2>&1
/home/usrmonit/bin/estrae_log.sh -a \"$INIZIO\" \"$FINE\"  >> $DIR_LOG/$LOG_FILE 2>&1
/home/usrmonit/bin/estrae_log.sh -l \"$INIZIO\" \"$FINE\"  >> $DIR_LOG/$LOG_FILE 2>&1
/home/usrmonit/bin/estrae_log.sh -d \"$INIZIO\" \"$FINE\"  >> $DIR_LOG/$LOG_FILE 2>&1
/home/usrmonit/bin/estrae_log.sh -r \"$INIZIO\" \"$FINE\"  >> $DIR_LOG/$LOG_FILE 2>&1
/home/usrmonit/bin/estrae_log.sh -k \"$INIZIO\" \"$FINE\"  >> $DIR_LOG/$LOG_FILE 2>&1
/home/usrmonit/bin/estrae_log.sh -m \"$INIZIO\" \"$FINE\"  >> $DIR_LOG/$LOG_FILE 2>&1
/home/usrmonit/bin/estrae_log.sh -S \"$INIZIO\" \"$FINE\"  >> $DIR_LOG/$LOG_FILE 2>&1  " > /dev/null 2>&1 &

echo "$(time_stamp) --> Esecuzione su 10.207.149.171"
$SSH CFTAdm11  cft@10.207.149.171 "
export HOSTNAME=\$(hostname)
/home/cft/bin/estrae_log.sh -c \"$INIZIO\" \"$FINE\"  >> $DIR_LOG_DB/$LOG_FILE 2>&1
/home/cft/bin/estrae_log.sh -a \"$INIZIO\" \"$FINE\"  >> $DIR_LOG_DB/$LOG_FILE 2>&1
/home/cft/bin/estrae_log.sh -l \"$INIZIO\" \"$FINE\"  >> $DIR_LOG_DB/$LOG_FILE 2>&1
/home/cft/bin/estrae_log.sh -d \"$INIZIO\" \"$FINE\"  >> $DIR_LOG_DB/$LOG_FILE 2>&1
/home/cft/bin/estrae_log.sh -r \"$INIZIO\" \"$FINE\"  >> $DIR_LOG_DB/$LOG_FILE 2>&1
/home/cft/bin/estrae_log.sh -k \"$INIZIO\" \"$FINE\"  >> $DIR_LOG_DB/$LOG_FILE 2>&1  " > /dev/null 2>&1 &

}
################################################################################################################

collect(){

echo "$(time_stamp) --> Collect logs"
$SCP_FROM  Password $DIR_LOG/* was@10.207.149.38
$SCP_FROM  Password $DIR_LOG/* was@10.207.149.42
$SCP_FROM  Password $DIR_LOG/* was@10.207.213.100
$SCP_FROM  Password $DIR_LOG/* was@10.207.213.101
$SCP_FROM  Password $DIR_LOG/* was@10.207.213.102
$SCP_FROM  Password $DIR_LOG/* was@10.207.213.103
$SCP_FROM  Password $DIR_LOG/* was@10.207.213.105
$SCP_FROM  Mon121Pr $DIR_LOG/* usrmonit@10.207.149.160
$SCP_FROM  CFTAdm11 $DIR_LOG_DB/* cft@10.207.149.171

}
 ##########################################################################################

# Checks number of arguments

check_argv(){
if [ $NPARAM -lt $MINARG ]; then
	echo
	echo "$(time_stamp) --> Numero argomenti non corretto"
	echo
	show_help
fi
}
##########################################################################################

show_help(){

INIZIO=$(date +"%h %d %H")
ORA=$(date +%H)

echo "--------------------------------------------------------------
Inserire a command line le due date di inizio e fine test es:
$0 \"$INIZIO\" \"$INIZIO\"

Mesi corretti:
      \"Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec\"

Per ora di fine si intendono tutti i minuti dell'ora.
Es: \"$INIZIO\" \"$INIZIO\" --> range [$ORA:00-$ORA:59]
--------------------------------------------------------------"

}

#######################################################################################################
check_orario(){

if [ $# -lt 3 ] ; then
    echo "$(time_stamp) --> Orario non corretto: $1 $2 $3"
    exit 1
else
  MESE=$1
  GIORNO=$2
  ORA=$3
  #Check mese
  case "$MESE" in
    Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)
    if [ $GIORNO -le 31 ]; then
        if [ $ORA -gt 24 ]; then
           echo "$(time_stamp) --> Orario non corretto: Ora $ORA"
           exit 1
        fi
    else
       echo "$(time_stamp) --> Giorno non corretto: Giorno $GIORNO"
       exit 1
    fi
    ;;
    *)
     echo "$(time_stamp) --> Mese non corretto $MESE"
     echo "$(time_stamp) --> Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec"
     exit 1
   esac
fi
}
#######################################################################################################

NPARAM=$#
MINARG=2
check_argv
ORARIO_INIZIO_INPUT=$1
ORARIO_FINE_INPUT=$2
# Controllo formale dati di input
check_orario $ORARIO_INIZIO_INPUT
check_orario $ORARIO_FINE_INPUT
extract
echo "$(time_stamp) --> Attesa del completamento delle sessioni ssh"
#read
wait
collect