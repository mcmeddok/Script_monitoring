#!/usr/bin/ksh
# Estrazione native_stderr.log
#
# TODO:
#     DONE 1) check presenza file di log
#     DONE 2) check data di estrazione presente nei file di log
#     DONE 3) diaglog
#     DONE 5) outbound
#     6) definire la naming convention per favorire la selezione in Log Analyser
#     DONE 7) check fine file su naming.log  e numero di retry
#
# /usr/IBM/WebSphere/AppServer/profiles/AppSrv02/logs/DB012/native_stderr.log
# /usr/IBM/WebSphere/AppServer/profiles/AppSrv02/logs/DB012/SystemOut.log
# /usr/IBM/HTTPServer/Delta/HTTP11/logs/perf_log
#
#####################################################################################

# Configurazione Parametri
DIR_LOG=/usr/IBM/WebSphere/AppServer/profiles
DIR_LOG_HTTP=/usr/IBM/HTTPServer/Delta
DIR_APPOGGIO=/tmp/estrazione_log
DIR_BIN=/home/was/bin
DIR_DB2LOCKTIMEOUT=/home/db2isdp1/sqllib/db2dump
DIR_HADR=/home/cft/snap
DIR_SNAP=/home/cft/snap
DIR_SDP_LOG=/usr/IBM/WebSphere/SDP_log
#DIR_HADR=/home/db2isdp1/tuning
LOG_HADR=contatori_hadr
LOG_INDOUBT=/home/db2isdp1/mydir/CERCA_INDOUBT/CERCA_PERSISTENT_INDOUBT.sh.v2.2.out
LOG_FIRSTLSN=/home/db2isdp1/mydir/CERCA_FIRSTLSN/CERCA_FIRSTLSN.sh.v2.2.out

#####################################################################################
#
#  Funzione di Help
#
#
#
#
#####################################################################################
show_help(){

INIZIO=$(date +"%h %d %H")
ORA=$(date +%H)

echo "
-------------------------------------------------------------------------
Script estrazione file di log per orario

   -e    Estrazione native_stderr.log
   -s    Estrazione SystemOut.log
   -p    Estrazione perf_log ed error_log da HTTP
   -a    Estrazione SAR cpu log (Web, DB)
   -P    Estrazione SAR -P all log  (WAS)
   -k    Estrazione SAR disk log  (DB)
   -d    Estrazione db2diag
   -r    Estrazione contatori HADR
   -m    Estrazione log script Montini
   -o    Estrazione outbound e inbound
   -n    Estrazione nconn
   -D    Estrazione SDP.log
   -l    Collect db2locktimeout (lista file + primi 20)
   -j    Collect dei javacore
   -t    Collect check_http
   -S    Collect dbmsnap e dbsnap

   -c    Cancella directory appoggio  $DIR_APPOGGIO
   -h    Help

Fornire orario di inizio e orario di fine estrazione nel seguente formato

Mese Giorno Ora Es: \"Sep 22 19\"

Mesi corretti:
  Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec

$0  -e \"Sep 22 05\" \"Sep 22 20\"
$0  -e \"$INIZIO\" \"$INIZIO\"

Per ora di fine si intendono tutti i minuti dell'ora.
Es: \"$INIZIO\" \"$INIZIO\" --> range [$ORA:00-$ORA:59]
      "

}
#####################################################################################
##########################################################################################
#
# Funzione per la data utilizzata nei log
#
# Formato: Jul 25 09:39:02
#          %b  %d %H:%M:%S
#
##########################################################################################
time_stamp(){
date +%b\ %d\ %H:%M:%S
}
##########################################################################################
clean_empty(){
find  $DIR_APPOGGIO -size 0c -exec rm {} \;
}
##########################################################################################
create_compress(){
PATTERN_FILE=$1
/usr/bin/gzip -f $DIR_APPOGGIO/$PATTERN_FILE  2> /dev/null
}
##########################################################################################
# Formato 20110518123202
#         AAAAMMGGHHmmss
range_log_hadr(){

DATA_INIZIO_LOG=$(head -10 $FILE_LOG | grep -v "DATA_ORA,PRIMARY_LOG," | head -1 | awk -F, '{ print $1 }')
DATA_FINE_LOG=$(tail -10 $FILE_LOG | grep -v "DATA_ORA,PRIMARY_LOG," | head -1 | awk -F, '{ print $1 }')

# Elimino il trattino
DATA_INIZIO_LOG=$(echo $DATA_INIZIO_LOG | awk -F- '{ print $1 $2 }')
DATA_FINE_LOG=$(echo $DATA_FINE_LOG | awk -F- '{ print $1 $2 }')


}
##########################################################################################
# restituisce la data in formato numerico per controllo con http
#
#  Formato input http:  18/May/2011:09
#  Formato output:      2010110711
#                       AAAAMMGGHH
#
http2range(){
DATA_TEMP=$1
DATA_TEMP=$(echo $DATA_TEMP | tr "\/" ":")

#echo $DATA_TEMP

MESE=$(echo $DATA_TEMP | awk -F: '{ print $2 }' )
GIORNO=$(echo $DATA_TEMP | awk -F: '{ print $1 }' )
ORA=$(echo $DATA_TEMP | awk -F: '{ print $4 }' )
ANNO=$(echo $DATA_TEMP | awk -F: '{ print $3 }' )

#echo "$MESE $GIORNO $ORA $ANNO"

# Ritorna MESE_NUM
trasforma_mese_letter2num

DATA_TEMP="$ANNO""$MESE_NUM""$GIORNO""$ORA"

echo $DATA_TEMP

}
##########################################################################################
# restituisce la data in formato numerico per controllo con native
#
# Formato native "May 13 13"
#
# Formato data numerica
# 20101107-11
# AAAAMMGG-HH
#
native2hadr(){
MESE=$1
GIORNO=$2
ORA=$3
ANNO=$(date +%Y)

# Ritorna MESE_NUM
trasforma_mese_letter2num

TEMP_DATA="$ANNO""$MESE_NUM""$GIORNO"-"$ORA"

echo $TEMP_DATA

}
##########################################################################################
# restituisce la data in formato numerico per controllo con native
#
# Formato native "May 13 13"
#
# Formato data numerica
# 2010110711049049
# AAAAMMGGHH0mm0ss
#
native2range(){
MESE=$1
GIORNO=$2
ORA=$3
ANNO=$(date +%Y)

# Ritorna MESE_NUM
trasforma_mese_letter2num

TEMP_DATA="$ANNO""$MESE_NUM""$GIORNO""$ORA"

echo $TEMP_DATA

}
##########################################################################################
##########################################################################################
# restituisce la data in formato montini
#
# Formato native "May 03 03"
#
# Formato montini  "May  3 03"    (nota: se day<10 mettere lo spazio)
#
native2montini(){
MESE=$1
GIORNO=$2
ORA=$3

GIORNO=$(expr $GIORNO + 1 - 1 )
if [ $GIORNO -le 9 ]; then
  GIORNO="  $GIORNO"
else
  GIORNO=" $GIORNO"
fi

}
##########################################################################################
range_perflog_http(){
DATA_INIZIO_LOG=$(head -1 $FILE_LOG | awk '{ print $4 }' | tr "[" ":" | tr "/" ":" )
DATA_FINE_LOG=$(tail -1 $FILE_LOG | awk '{ print $4 }' | tr "[" ":" | tr "/" ":" )

# Formato :10:May:2011:15:22:19
#echo "$DATA_INIZIO_LOG $DATA_FINE_LOG"

MESE_INIZIO=$(echo $DATA_INIZIO_LOG | awk -F: '{ print $3 }')
MESE_FINE=$(echo $DATA_FINE_LOG | awk -F: '{ print $3 }')

ANNO_INIZIO=$(echo $DATA_INIZIO_LOG | awk -F: '{ print $4 }')
ANNO_FINE=$(echo $DATA_FINE_LOG | awk -F: '{ print $4 }')

GIORNO_INIZIO=$(echo $DATA_INIZIO_LOG | awk -F: '{ print $2 }')
GIORNO_FINE=$(echo $DATA_FINE_LOG | awk -F: '{ print $2 }')

ORA_INIZIO=$(echo $DATA_INIZIO_LOG | awk -F: '{ print $5 }')
ORA_FINE=$(echo $DATA_FINE_LOG | awk -F: '{ print $5 }')

MIN_INIZIO=$(echo $DATA_INIZIO_LOG | awk -F: '{ print $6 }')
MIN_FINE=$(echo $DATA_FINE_LOG | awk -F: '{ print $6 }')

MESE=$MESE_INIZIO
# Ritorna MESE_NUM
trasforma_mese_letter2num
DATA_INIZIO_LOG=$ANNO_INIZIO$MESE_NUM$GIORNO_INIZIO$ORA_INIZIO$MIN_INIZIO

MESE=$MESE_FINE
# Ritorna MESE_NUM
trasforma_mese_letter2num
DATA_FINE_LOG=$ANNO_FINE$MESE_NUM$GIORNO_FINE$ORA_FINE$MIN_FINE

# Formato data numerica http
# 201011071149
# AAAAMMGGHHmm

#echo $DATA_INIZIO_LOG $DATA_FINE_LOG

}
##########################################################################################
check_giorno(){

GG_INIZIO=$(echo $ORARIO_INIZIO_INPUT | awk '{ print $2 }')
GG_FINE=$(echo $ORARIO_FINE_INPUT | awk '{ print $2 }')

if [ $GG_INIZIO = $GG_FINE ]; then
    GG_FILE=$GG_INIZIO
else
    echo "$(time_stamp) --> Giorno di inizio e fine differenti, si utilizza il giorno di inizio $GG_INIZIO"
    GG_FILE=$GG_INIZIO
fi

}
##########################################################################################
range_log_http(){
DATA_INIZIO_LOG=$(grep "^\[" $FILE_LOG | head -1 | awk '{ print $1 }' | tr "[" ":" | tr "]" ":" | tr "/" ":")
DATA_FINE_LOG=$(tail -100 $FILE_LOG |  grep "^\[" | tail -1 | awk '{ print $1 }' | tr "[" ":" | tr "]" ":" | tr "/" ":")

#echo "$DATA_INIZIO_LOG $DATA_FINE_LOG"

MESE_INIZIO=$(echo $DATA_INIZIO_LOG | awk -F: '{ print $3 }')
MESE_FINE=$(echo $DATA_FINE_LOG | awk -F: '{ print $3 }')

ANNO_INIZIO=$(echo $DATA_INIZIO_LOG | awk -F: '{ print $4 }')
ANNO_FINE=$(echo $DATA_FINE_LOG | awk -F: '{ print $4 }')

GIORNO_INIZIO=$(echo $DATA_INIZIO_LOG | awk -F: '{ print $2 }')
GIORNO_FINE=$(echo $DATA_FINE_LOG | awk -F: '{ print $2 }')

ORA_INIZIO=$(echo $DATA_INIZIO_LOG | awk -F: '{ print $5 }')
ORA_FINE=$(echo $DATA_FINE_LOG | awk -F: '{ print $5 }')

MIN_INIZIO=$(echo $DATA_INIZIO_LOG | awk -F: '{ print $6 }')
MIN_FINE=$(echo $DATA_FINE_LOG | awk -F: '{ print $6 }')

MESE=$MESE_INIZIO
# Ritorna MESE_NUM
trasforma_mese_letter2num
DATA_INIZIO_LOG=$ANNO_INIZIO$MESE_NUM$GIORNO_INIZIO$ORA_INIZIO$MIN_INIZIO

MESE=$MESE_FINE
# Ritorna MESE_NUM
trasforma_mese_letter2num
DATA_FINE_LOG=$ANNO_FINE$MESE_NUM$GIORNO_FINE$ORA_FINE$MIN_FINE

# Formato data numerica http
# 201011071149
# AAAAMMGGHHmm

#echo $DATA_INIZIO_LOG $DATA_FINE_LOG

}
##########################################################################################
# LOOP 1 - Wed Jun 29 18:09:01 METDST 2011
#
range_log_montini(){
DATA_INIZIO_LOG=$(grep LOOP $FILE_LOG | head -1 | awk -F: '{print $1 " " $2 " " $3 }' | awk '{print $5 " " $6 " " $7 $8 " " $11 }' )
DATA_FINE_LOG=$(tail -100 $FILE_LOG | grep LOOP | tail -1 | awk -F: '{print $1 " " $2 " " $3 }' | awk '{print $5 " " $6 " " $7 $8 " " $11}' )

#echo "$DATA_INIZIO_LOG"
#echo "$DATA_FINE_LOG"

MESE_INIZIO=$(echo $DATA_INIZIO_LOG | awk '{ print $1 }')
MESE_FINE=$(echo $DATA_FINE_LOG | awk '{ print $1 }')

ANNO_INIZIO=$(echo $DATA_INIZIO_LOG | awk '{ print $4 }')
ANNO_FINE=$(echo $DATA_FINE_LOG | awk '{ print $4 }')

GIORNO_INIZIO=$(echo $DATA_INIZIO_LOG | awk '{ print $2 }')
GIORNO_FINE=$(echo $DATA_FINE_LOG | awk '{ print $2 }')

if [ "$GIORNO_INIZIO" -le 9 ]; then
    GIORNO_INIZIO=0$GIORNO_INIZIO
fi
if [ "$GIORNO_FINE" -le 9 ]; then
    GIORNO_FINE=0$GIORNO_FINE
fi

ORA_INIZIO=$(echo $DATA_INIZIO_LOG | awk '{ print $3 }')
ORA_FINE=$(echo $DATA_FINE_LOG | awk '{ print $3 }')

#echo    $MESE_INIZIO $MESE_FINE

MESE=$MESE_INIZIO
# Ritorna MESE_NUM
trasforma_mese_letter2num
DATA_INIZIO_LOG=$ANNO_INIZIO$MESE_NUM$GIORNO_INIZIO$ORA_INIZIO

MESE=$MESE_FINE
# Ritorna MESE_NUM
trasforma_mese_letter2num
DATA_FINE_LOG=$ANNO_FINE$MESE_NUM$GIORNO_FINE$ORA_FINE

# Formato data numerica http
# 201011071149
# AAAAMMGGHHmm

#echo $DATA_INIZIO_LOG $DATA_FINE_LOG

}
##########################################################################################
range_log_native(){
DATA_INIZIO_LOG=$(grep timestamp $FILE_LOG | head -1 | awk -F\" '{ print $6 }' | tr ":" "0")
DATA_FINE_LOG=$(tail -100 $FILE_LOG | grep timestamp | tail -1 | awk -F\" '{ print $6 }' | tr ":" "0")

MESE_INIZIO=$(echo $DATA_INIZIO_LOG | awk '{ print $1 }')
MESE_FINE=$(echo $DATA_FINE_LOG | awk '{ print $1 }')

ANNO_INIZIO=$(echo $DATA_INIZIO_LOG | awk '{ print $4 }')
ANNO_FINE=$(echo $DATA_FINE_LOG | awk '{ print $4 }')

GIORNO_ORA_INIZIO=$(echo $DATA_INIZIO_LOG | awk '{ print $2 $3 }')
GIORNO_ORA_FINE=$(echo $DATA_FINE_LOG | awk '{ print $2 $3 }')

MESE=$MESE_INIZIO
# Ritorna MESE_NUM
trasforma_mese_letter2num
DATA_INIZIO_LOG=$ANNO_INIZIO$MESE_NUM$GIORNO_ORA_INIZIO

MESE=$MESE_FINE
# Ritorna MESE_NUM
trasforma_mese_letter2num
DATA_FINE_LOG=$ANNO_FINE$MESE_NUM$GIORNO_ORA_FINE

# Formato data numerica
# 2010110711049049
# AAAAMMGGHH0mm0ss

#echo $DATA_INIZIO_LOG $DATA_FINE_LOG

}
##########################################################################################
range_log_SDP(){
ANNO=$(date +"%Y")
DATA_INIZIO_LOG=$(grep ^$ANNO $FILE_LOG | head -1 | awk -F: '{ print $1 $2 }' | tr "/" " " | awk '{ print $1 $2 $3 $4 }' )
DATA_FINE_LOG=$(grep ^$ANNO $FILE_LOG | tail -1 | awk -F: '{ print $1 $2 }' | tr "/" " " | awk '{ print $1 $2 $3 $4 }' )
}
##########################################################################################
range_log(){

DATA_INIZIO_LOG=$(grep CEST $FILE_LOG  | head -1 | awk '{ print $1 " " $2 }' | tr " " "." | tr "/" "." |  tr "[" "." | awk -F. '{ print $4 $3 $2 $5 }')

CHAR=$(echo $DATA_INIZIO_LOG | wc -c)

if [ $CHAR -lt 9 ]; then
   A=$(echo $DATA_INIZIO_LOG | cut -c 1-6 )
   B=$(echo $DATA_INIZIO_LOG | cut -c 7 )
   DATA_INIZIO_LOG=$A0$B
fi

DATA_FINE_LOG=$(grep CEST $FILE_LOG  | tail -1 | awk '{ print $1 " " $2 }' | tr " " "." | tr "/" "." |  tr "[" "." | awk -F. '{ print $4 $3 $2 $5 }')

if [ $CHAR -lt 9 ]; then
   A=$(echo $DATA_FINE_LOG | cut -c 1-6 )
   B=$(echo $DATA_FINE_LOG | cut -c 7 )
   DATA_FINE_LOG=$A0$B
fi

#echo $DATA_INIZIO_LOG $DATA_FINE_LOG

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

make_pivot(){
# Crea file pivot con il tool di Lorenzo

echo "$(time_stamp) --> Creazione file pivot $DIR_APPOGGIO/$FILE_OUT.cvs"
$DIR_BIN/httplog -v prefix=$SERVER_NAME $DIR_APPOGGIO/$FILE_OUT > $DIR_APPOGGIO/$FILE_OUT.cvs
rm -f  $DIR_APPOGGIO/$FILE_OUT

}
#######################################################################################################
check_orario_inizio_last(){

      NUM_RIGA_INIZIO=""

      NUM_RIGA_INIZIO=$(egrep -n "$ORARIO_INIZIO" $FILE_LOG | head -1 | awk -F: '{ print $1}')

      if [ "$NUM_RIGA_INIZIO" = "" ]; then
          echo "$(time_stamp) --> Orario di inizio non trovato"
          NUM_RIGA_INIZIO=$RIGHE_LOG
          return 1
      else
          echo "$(time_stamp) --> Numero di riga: $NUM_RIGA_INIZIO"
      fi

}
#######################################################################################################
#######################################################################################################
check_orario_fine_last(){

NUM_RIGA_FINE=""

NUM_RIGA_FINE=$(egrep -n "$ORARIO_FINE" $FILE_LOG | tail -1 | awk -F: '{ print $1}')

if [ "$NUM_RIGA_FINE" = "" ]; then
    echo "$(time_stamp) --> Orario di fine non trovato"
    NUM_RIGA_FINE=$RIGHE_LOG
    return 1
else
    echo "$(time_stamp) --> Numero di riga: $NUM_RIGA_FINE"
fi
}
#######################################################################################################
#######################################################################################################
check_orario_inizio(){

      NUM_RIGA_INIZIO=""

      NUM_RIGA_INIZIO=$(egrep -n "$ORARIO_INIZIO" $FILE_LOG | head -1 | awk -F: '{ print $1}')

      # delete
      #echo  "Inizio $ORARIO_INIZIO   fine: $ORARIO_FINE"

      if [ "$NUM_RIGA_INIZIO" = "" ]; then
          if [ "$ORARIO_FINE" != "$ORARIO_INIZIO" ]; then
              echo "$(time_stamp) --> Orario non trovato"
              VERSE="down"
              trova_orario $ORARIO_INIZIO
          else
                echo "$(time_stamp) --> Orario di inizio non trovato"
                NUM_RIGA_INIZIO=$RIGHE_LOG
                return 1
          fi
      else
          echo "$(time_stamp) --> Numero di riga: $NUM_RIGA_INIZIO"
      fi

}
#######################################################################################################
check_orario_fine(){

NUM_RIGA_FINE=""

NUM_RIGA_FINE=$(egrep -n "$ORARIO_FINE" $FILE_LOG | tail -1 | awk -F: '{ print $1}')

if [ "$NUM_RIGA_FINE" = "" ]; then
   if [ "$ORARIO_FINE" != "$ORARIO_INIZIO" ] ; then
        echo "$(time_stamp) --> Orario non trovato"
        VERSE="up"
        trova_orario $ORARIO_FINE
   else
          echo "$(time_stamp) --> Orario di fine non trovato"
          NUM_RIGA_FINE=$RIGHE_LOG
          return 1
   fi
else
    echo "$(time_stamp) --> Numero di riga: $NUM_RIGA_FINE"
fi
}
#######################################################################################################
trova_orario(){
# Trova un orario di inizio presente nel file di log
# TODO Inserire anche il passaggio al mese precedente

case "$TIME_FORMAT" in
  native)
      MESE=$1
      GIORNO=$2
      ORA=$3
  ;;
  systemout)
      MESE=$(echo $1 | cut -c 5-6 )
      GIORNO=$(echo $1 | cut -c 1-2 )
      ANNO=$(echo $1 | cut -c 9-10 )
      ORA=$(echo $2 |  awk -F. '{ print $1 }')
  ;;
  http)
      MESE=$(echo $1 | cut -c 4-6 )
      GIORNO=$(echo $1 | cut -c 1-2 )
      ANNO=$(echo $1 | cut -c 8-11 )
      ORA=$(echo $1 |  cut -c 13-14 )
  ;;
  hadr)
      ANNO=$(echo $1 | cut -c 1-4 )
      MESE=$(echo $1 | cut -c 5-6 )
      GIORNO=$(echo $1 | cut -c 7-8 )
      ORA=$(echo $1 |  cut -c 10-11 )
  ;;
  montini)
      # Jul 5 09
      MESE=$1
      GIORNO=$2
      ORA=$3
  ;;
  SDP)
      #  2011/07/04 19:19
      ANNO=$(echo $1 | cut -c 1-4 )
      MESE=$(echo $1 | cut -c 6-7 )
      GIORNO=$(echo $1 | cut -c 9-10 )
      ORA=$2
esac

if  [ "$VERSE" = "up" ]; then
  if [ $ORA -gt 0 ]; then
      ORA=$(expr $ORA - 1 )
      if [ $ORA -le 9 ]; then
          ORA=0$ORA
      fi
  else
    GIORNO=$(expr $GIORNO - 1 )
      if [ $GIORNO -le 9 ]; then
          GIORNO=0$GIORNO
      fi
    ORA=23
  fi
fi

if  [ "$VERSE" = "down" ]; then
  if [ $ORA -lt 23 ]; then
      ORA=$(expr $ORA + 1 )
      if [ $ORA -le 9 ]; then
          ORA=0$ORA
      fi
  else
    GIORNO=$(expr $GIORNO + 1 )
      if [ $GIORNO -le 9 ]; then
          GIORNO=0$GIORNO
      fi
    ORA=00
  fi
fi

case "$TIME_FORMAT" in
     native)
         if  [ "$VERSE" = "down" ]; then
          ORARIO_INIZIO="$MESE $GIORNO $ORA"
         elif [ "$VERSE" = "up" ]; then
          ORARIO_FINE="$MESE $GIORNO $ORA"
         fi
     ;;
     systemout)
         ORA=$(expr $ORA + 1 - 1 )
         if  [ "$VERSE" = "down" ]; then
          ORARIO_INIZIO="$GIORNO\/$MESE\/$ANNO $ORA."
         elif [ "$VERSE" = "up" ]; then
          ORARIO_FINE="$GIORNO\/$MESE\/$ANNO $ORA."
         fi
     ;;
     http)
         if  [ "$VERSE" = "down" ]; then
          ORARIO_INIZIO="$GIORNO/$MESE/$ANNO:$ORA"
         elif [ "$VERSE" = "up" ]; then
          ORARIO_FINE="$GIORNO/$MESE/$ANNO:$ORA"
         fi
     ;;
     hadr)
         if  [ "$VERSE" = "down" ]; then
           ORARIO_INIZIO="$ANNO$MESE$GIORNO-$ORA"
         elif [ "$VERSE" = "up" ]; then
           ORARIO_FINE="$ANNO$MESE$GIORNO-$ORA"
         fi
      ;;
      montini)
         GIORNO=$(expr $GIORNO + 1 - 1 )
         if  [ "$VERSE" = "down" ]; then
          ORARIO_INIZIO="$MESE $GIORNO $ORA"
         elif [ "$VERSE" = "up" ]; then
          ORARIO_FINE="$MESE $GIORNO $ORA"
         fi
      ;;
      SDP)
         #  2011/07/04 19:19
         if  [ "$VERSE" = "down" ]; then
          ORARIO_INIZIO="$ANNO/$MESE/$GIORNO $ORA"
         elif [ "$VERSE" = "up" ]; then
          ORARIO_FINE="$ANNO/$MESE/$GIORNO $ORA"
         fi

esac

 if  [ "$VERSE" = "down" ]; then
      echo "$(time_stamp) --> Nuovo Orario inizio: $ORARIO_INIZIO"
      if [ "$ORARIO_INIZIO" = "$ORARIO_FINE" ]; then
        check_orario_inizio_last
      else
        check_orario_inizio
      fi
 elif [ "$VERSE" = "up" ]; then
      echo "$(time_stamp) --> Nuovo Orario fine: $ORARIO_FINE"
      if [ "$ORARIO_INIZIO" = "$ORARIO_FINE" ]; then
        check_orario_fine_last
      else
        check_orario_fine
      fi
 fi


}
#######################################################################################################
#######################################################################################################
trova_orario_up_other(){
# Trova un orario di inizio presente nel file di log
# TODO Inserire anche il passaggio al mese precedente

  MESE=$(echo $1 | cut -c 5-6 )
  GIORNO=$(echo $1 | cut -c 1-2 )
  ANNO=$(echo $1 | cut -c 9-10 )
  ORA=$2

  if [ $ORA -gt 0 ]; then
      ORA=$(expr $ORA - 1 )
      if [ $ORA -le 9 ]; then
          ORA=0$ORA
      fi
  else
    GIORNO=$(expr $GIORNO - 1 )
      if [ $GIORNO -le 9 ]; then
          GIORNO=0$GIORNO
      fi
    ORA=23
  fi


ORARIO_INIZIO="$GIORNO\/$MESE\/$ANNO $ORA"
echo "$(time_stamp) --> Nuovo Orario inizio: $ORARIO_INIZIO"
check_orario_inizio
}
######################################################################################################
#######################################################################################################
trova_orario_down_other(){
# Trova un orario di fine presente nel file di log

# TODO Inserire anche il passaggio al mese precedente

  MESE=$(echo $1 | cut -c 5-6 )
  GIORNO=$(echo $1 | cut -c 1-2 )
  ANNO=$(echo $1 | cut -c 9-10 )
  ORA=$2

  if [ $ORA -lt 23 ]; then
      ORA=$(expr $ORA + 1 )
      if [ $ORA -le 9 ]; then
          ORA=0$ORA
      fi
  else
    GIORNO=$(expr $GIORNO + 1 )
      if [ $GIORNO -le 9 ]; then
          GIORNO=0$GIORNO
      fi
    ORA=00
  fi

ORARIO_FINE="$GIORNO\/$MESE\/$ANNO $ORA"
echo "$(time_stamp) --> Nuovo Orario fine: $ORARIO_FINE"
check_orario_fine
}
#######################################################################################################
#######################################################################################################
trova_orario_down(){
# Trova un orario di fine presente nel file di log

# TODO Inserire anche il passaggio al mese precedente

  MESE=$1
  GIORNO=$2
  ORA=$3

  if [ $ORA -lt 23 ]; then
      ORA=$(expr $ORA + 1 )
      if [ $ORA -le 9 ]; then
          ORA=0$ORA
      fi
  else
    GIORNO=$(expr $GIORNO + 1 )
      if [ $GIORNO -le 9 ]; then
          GIORNO=0$GIORNO
      fi
    ORA=00
  fi

ORARIO_FINE="$MESE $GIORNO $ORA"
echo "$(time_stamp) --> Nuovo Orario fine: $ORARIO_FINE"
check_orario_fine
}
#######################################################################################################
estrae_log_compress(){

TAIL_LINE=$(expr $RIGHE_LOG - $NUM_RIGA_INIZIO + 1 )
HEAD_LINE=$(expr $NUM_RIGA_FINE - $NUM_RIGA_INIZIO )

#echo $TAIL_LINE
#echo $HEAD_LINE

#FILE_OUT=$(echo $FILE_LOG | awk -F/ '{ print $7 "."  $9 "." $10 }')

tail -$TAIL_LINE $FILE_LOG | head -$HEAD_LINE | gzip -c  > $DIR_APPOGGIO/$FILE_OUT.gz

}
#######################################################################################################
#######################################################################################################
estrae_log(){

TAIL_LINE=$(expr $RIGHE_LOG - $NUM_RIGA_INIZIO + 1 )
HEAD_LINE=$(expr $NUM_RIGA_FINE - $NUM_RIGA_INIZIO )

#echo $TAIL_LINE
#echo $HEAD_LINE

#FILE_OUT=$(echo $FILE_LOG | awk -F/ '{ print $7 "."  $9 "." $10 }')

tail -$TAIL_LINE $FILE_LOG | head -$HEAD_LINE  > $DIR_APPOGGIO/$FILE_OUT

}
#######################################################################################################
lista_log_http(){

FILE_LOG_NAME=$1

LISTA_LOG=$(find $DIR_LOG_HTTP -name $FILE_LOG_NAME )

}
#######################################################################################################
#######################################################################################################
lista_log_SDP(){

FILE_LOG_NAME=$1

echo "$(time_stamp) --> Estrazione solo dei log 12 16 22 26"
LISTA_LOG=$(find $DIR_LOG -name $FILE_LOG_NAME | grep -e 12 -e 22 -e 16 -e 26)
#LISTA_LOG=$(find $DIR_LOG -name $FILE_LOG_NAME )

}
#######################################################################################################
#######################################################################################################
lista_log(){

FILE_LOG_NAME=$1

LISTA_LOG=$(find $DIR_LOG -name $FILE_LOG_NAME | egrep "DB0|DA0" | egrep -v "2010|2011")

}
#######################################################################################################
packaging(){

LOGTYPE_NAME=$1

ARCHIVE_NAME=$HOSTNAME.$LOGTYPE_NAME.$RANGE_ORARIO

cd $DIR_APPOGGIO

tar -cvf /home/was/scriptSDP/$ARCHIVE_NAME.tar *.$LOGTYPE_NAME

rm -f *.$LOGTYPE_NAME

cd - > /dev/null 2>&1

gzip $ARCHIVE_NAME.tar

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
trasforma_orario_SDP(){

# Esempio formato
# 2011/07/04 19:19:40:507

ANNO=$(date +%Y)
MESE=$1
GIORNO=$2
ORA=$3

trasforma_mese_letter2num

echo "$ANNO/$MESE_NUM/$GIORNO $ORA"

}
#######################################################################################################
#######################################################################################################
trasforma_orario_http(){

# Esempio formato
# 10.207.213.67 - - [24/Feb/2011:10:11:02 +0100]

ANNO=$(date +%Y)
MESE=$1
GIORNO=$2
ORA=$3

echo "$GIORNO/$MESE/$ANNO:$ORA"

}
#######################################################################################################
trasforma_sysout(){

echo "$(time_stamp) --> Trasformazione . in : per il file sysout"

awk '/CEST/{gsub(/\./, ":")};{print}' $DIR_APPOGGIO/$FILE_OUT > $DIR_APPOGGIO/no-punti

mv  $DIR_APPOGGIO/no-punti  $DIR_APPOGGIO/$FILE_OUT

}
#######################################################################################################
create_sar_cpu(){

DATA_SAR=$(date +%Y%m%d)
#FILE_LOG=$HOSTNAME.$DATA_SAR.sar.log
FILE_LOG=$HOSTNAME.sar-cpu.log

GIORNO_SAR=$(date +%d)
GIORNO_SAR_INPUT=$(echo $ORARIO_INIZIO_INPUT | awk '{ print $2 }')


if [ "$GIORNO_SAR" = "$GIORNO_SAR_INPUT" ]; then
    SAR_PAR=""
else
    SAR_PAR="-f /var/adm/sa/sa$GIORNO_SAR_INPUT"
fi

SAR_INIZIO=$(echo $ORARIO_INIZIO_INPUT | awk '{ print $3 }')
SAR_FINE=$(echo $ORARIO_FINE_INPUT | awk '{ print $3 }')

if [ "$PLATFORM" = "AIX" ]; then
  sar $SAR_PAR -s$SAR_INIZIO -e$SAR_FINE:59 > $DIR_APPOGGIO/$FILE_LOG
fi

if [ "$PLATFORM" = "HP-UX" ]; then
  sar $SAR_PAR -s$SAR_INIZIO -e$SAR_FINE:59 > $DIR_APPOGGIO/$FILE_LOG
fi
}
#######################################################################################################
#######################################################################################################
create_sar_disk(){

DATA_SAR=$(date +%Y%m%d)
#FILE_LOG=$HOSTNAME.$DATA_SAR.sar.log
FILE_LOG=$HOSTNAME.sar-disk.log

GIORNO_SAR=$(date +%d)
GIORNO_SAR_INPUT=$(echo $ORARIO_INIZIO_INPUT | awk '{ print $2 }')


if [ "$GIORNO_SAR" = "$GIORNO_SAR_INPUT" ]; then
    SAR_PAR=""
else
    SAR_PAR="-f /var/adm/sa/sa$GIORNO_SAR_INPUT"
fi

SAR_INIZIO=$(echo $ORARIO_INIZIO_INPUT | awk '{ print $3 }')
SAR_FINE=$(echo $ORARIO_FINE_INPUT | awk '{ print $3 }')

if [ "$PLATFORM" = "AIX" ]; then
  sar $SAR_PAR -d -s$SAR_INIZIO -e$SAR_FINE:59 > $DIR_APPOGGIO/$FILE_LOG
fi

if [ "$PLATFORM" = "HP-UX" ]; then
  sar $SAR_PAR -d -s$SAR_INIZIO -e$SAR_FINE:59 > $DIR_APPOGGIO/$FILE_LOG
fi
}
#######################################################################################################
#######################################################################################################
create_sar(){

DATA_SAR=$(date +%Y%m%d)
#FILE_LOG=$HOSTNAME.$DATA_SAR.sar.log
FILE_LOG=$HOSTNAME.sar.log

GIORNO_SAR=$(date +%d)
GIORNO_SAR_INPUT=$(echo $ORARIO_INIZIO_INPUT | awk '{ print $2 }')


if [ "$GIORNO_SAR" = "$GIORNO_SAR_INPUT" ]; then
    SAR_PAR=""
else
    SAR_PAR="-f /var/adm/sa/sa$GIORNO_SAR_INPUT"
fi

SAR_INIZIO=$(echo $ORARIO_INIZIO_INPUT | awk '{ print $3 }')
SAR_FINE=$(echo $ORARIO_FINE_INPUT | awk '{ print $3 }')

if [ "$PLATFORM" = "AIX" ]; then
  sar $SAR_PAR -P ALL -s$SAR_INIZIO -e$SAR_FINE:59 > $DIR_APPOGGIO/$FILE_LOG
fi

if [ "$PLATFORM" = "HP-UX" ]; then
  sar $SAR_PAR -s$SAR_INIZIO -e$SAR_FINE:59 > $DIR_APPOGGIO/$FILE_LOG
fi
}
#######################################################################################################
# Collect file check_HTTP
#
# Formato:  check_HTTP11.txt.29  check_HTTP13.log
#                     check_HTTP<xx>.txt.<giorno>
# Eccezione per lo 0, che è l'ultimo giorno del mese precedente
# Il log del giorno non ha il numero finale
#
collect_check_HTTP(){

TODAY=$(date +"%h %d")

# Prendiamo i file del giorno finale se i giorni sono diversi
GIORNO_START=$(echo $ORARIO_INIZIO_INPUT | awk '{ print $2 }')
GIORNO_END=$(echo $ORARIO_FINE_INPUT | awk '{ print $2 }')
ORA_START=$(echo $ORARIO_INIZIO_INPUT | awk '{ print $3 }')
ORA_END=$(echo $ORARIO_FINE_INPUT | awk '{ print $3 }')

if [ $GIORNO_START = $GIORNO_END ] ; then
   GIORNO=$GIORNO_START
else
  echo "$(time_stamp) --> Estrazione non dello stesso giorno, si considera il giorno finale"
  GIORNO=$GIORNO_END
fi


ANNO=$(date +%Y)
MESE=$(echo $ORARIO_FINE_INPUT | awk '{ print $1 }')
MESE_GIORNO="$MESE $GIORNO"
# Tolgo lo zero iniziale
GIORNO=$(expr $GIORNO + 1 - 1 )

#echo  $TODAY $MESE_GIORNO

if [ "$TODAY" = "$MESE_GIORNO" ] ; then
    FINALE_FILE=""
else
      if [ $GIORNO = 31 ]; then
          GIORNO_FILE=0
      fi

      if [ $GIORNO = 30 ]; then
         if [ $MESE = "Apr"|$MESE ="Jun"|$MESE ="Sep"|$MESE ="Nov" ] ; then
          GIORNO_FILE=0
         else
          GIORNO_FILE=$GIORNO
         fi
      fi

      if [ $GIORNO = 29 ]; then
         if [ $MESE = "Feb" ] ; then
          GIORNO_FILE=0
         else
          GIORNO_FILE=$GIORNO
         fi
      fi

      if [ $GIORNO = 28 ]; then
         if [ $MESE = "Feb" ] ; then
           if [ $ANNO = 2012 ] ; then
              GIORNO_FILE=$GIORNO
             else
              GIORNO_FILE=0
          fi
         fi
      fi

      if [ $GIORNO -lt 28 ]; then
         GIORNO_FILE=$GIORNO
      fi
      FINALE_FILE=.$GIORNO_FILE
fi

LISTA_LOG=$(ls /tmp/check_HTTP??.txt$FINALE_FILE )

for FILE_LOG in $LISTA_LOG
do
        echo  "$(time_stamp) --> Estrazione check_HTTP da $FILE_LOG"
        SERVER_HTTP=$(echo $FILE_LOG | awk -F/ '{ print $3 }' | awk -F. '{ print $1 }' )

        ORA=$ORA_START
        ORA=$(expr $ORA + 1 - 1 )
        if [ $ORA -le 9 ]; then
            ORA=0$ORA
        fi

        grep ^$ORA $FILE_LOG > $DIR_APPOGGIO/$HOSTNAME.$SERVER_HTTP.txt

        ORA=$(expr $ORA + 1 - 1 )
        ORA_END=$(expr $ORA_END + 1 - 1 )

        while [[ $ORA -lt $ORA_END ]] ; do
        	ORA=$(expr $ORA + 1 )
        	if [ $ORA -le 9 ]; then
              ORA=0$ORA
          fi
          grep ^$ORA $FILE_LOG >> $DIR_APPOGGIO/$HOSTNAME.$SERVER_HTTP.txt
        done
done

}
#######################################################################################################
# Collect dbmsnap
# directory /home/cft/snap
# Naming convention:   dbmsnap-AAAAMMGG_HHmm.txt
#
#
dbmsnap(){

ls $DIR_SNAP/dbmsnap*  | sort | awk -F/ '{ print $5 }' > $DIR_APPOGGIO/dbmsnap.tmp
ls $DIR_SNAP/dbsnap-*  | sort | awk -F/ '{ print $5 }' > $DIR_APPOGGIO/dbsnap.tmp

# Prendiamo i file del giorno finale se i giorni sono diversi
GIORNO_START=$(echo $ORARIO_INIZIO_INPUT | awk '{ print $2 }')
GIORNO_END=$(echo $ORARIO_FINE_INPUT | awk '{ print $2 }')

if [ $GIORNO_START = $GIORNO_END ] ; then
  GIORNO=$GIORNO_START
else
  echo "$(time_stamp) --> Estrazione non dello stesso giorno, si considera il giorno finale"
  GIORNO=$GIORNO_END
fi

ORA_START=$(echo $ORARIO_INIZIO_INPUT | awk '{ print $3 }')
ORA_END=$(echo $ORARIO_FINE_INPUT | awk '{ print $3 }')

ANNO=$(date +%Y)
MESE=$(echo $ORARIO_INIZIO_INPUT | awk '{ print $1 }')
trasforma_mese_letter2num

ORA=$ORA_START
#echo $ANNO$MESE_NUM$GIORNO"_"$ORA
grep $ANNO$MESE_NUM$GIORNO"_"$ORA  $DIR_APPOGGIO/dbmsnap.tmp > $DIR_APPOGGIO/$HOSTNAME.dbmsnap.lista
grep $ANNO$MESE_NUM$GIORNO"_"$ORA  $DIR_APPOGGIO/dbsnap.tmp > $DIR_APPOGGIO/$HOSTNAME.dbsnap.lista

while [[ $ORA -lt $ORA_END ]] ; do
	ORA=$(expr $ORA + 1 )
	if [ $ORA -le 9 ]; then
      ORA=0$ORA
  fi
  #echo .$ANNO-$MESE_NUM-$GIORNO-$ORA-
	grep $ANNO$MESE_NUM$GIORNO"_"$ORA  $DIR_APPOGGIO/dbmsnap.tmp >> $DIR_APPOGGIO/$HOSTNAME.dbmsnap.lista
	grep $ANNO$MESE_NUM$GIORNO"_"$ORA  $DIR_APPOGGIO/dbsnap.tmp >> $DIR_APPOGGIO/$HOSTNAME.dbsnap.lista
done

# Creazione tgz con i primi 20 file

COUNT_DB2LOCK=$(wc -l $DIR_APPOGGIO/$HOSTNAME.dbmsnap.lista | awk '{ print $1 }')
if [ $COUNT_DB2LOCK = 0 ]; then
    echo "$(time_stamp) --> File dbmsnap non presenti"
else
    echo "$(time_stamp) --> Presenti $COUNT_DB2LOCK file dbmsnap"
    echo "$(time_stamp) --> Creazione tgz"
    cd $DIR_SNAP
    cat $DIR_APPOGGIO/$HOSTNAME.dbmsnap.lista | xargs tar -cvf - | /usr/contrib/bin/gzip > $DIR_APPOGGIO/$HOSTNAME.dbmsnap_log.tgz
    cd - > /dev/null 2>&1
fi
rm -f $DIR_APPOGGIO/dbmsnap.tmp

COUNT_DB2LOCK=""
COUNT_DB2LOCK=$(wc -l $DIR_APPOGGIO/$HOSTNAME.dbsnap.lista | awk '{ print $1 }')
if [ $COUNT_DB2LOCK = 0 ]; then
    echo "$(time_stamp) --> File dbsnap non presenti"
else
    echo "$(time_stamp) --> Presenti $COUNT_DB2LOCK file dbsnap"
    echo "$(time_stamp) --> Creazione tgz"
    cd $DIR_SNAP
    cat $DIR_APPOGGIO/$HOSTNAME.dbsnap.lista | xargs tar -cvf - | /usr/contrib/bin/gzip > $DIR_APPOGGIO/$HOSTNAME.dbsnap_log.tgz
    cd - > /dev/null 2>&1
fi
rm -f $DIR_APPOGGIO/dbsnap.tmp

}
#######################################################################################################
# Collect nconn
# Naming convention: nconn_09.txt  nconn_13.txt
#
nconn(){
TODAY=$(date +"%h %d")
ANNO=$(date +"%Y")

# Prendiamo i file del giorno finale se i giorni sono diversi
GIORNO_START=$(echo $ORARIO_INIZIO_INPUT | awk '{ print $2 }')
GIORNO_END=$(echo $ORARIO_FINE_INPUT | awk '{ print $2 }')
ORA_START=$(echo $ORARIO_INIZIO_INPUT | awk '{ print $3 }')
ORA_END=$(echo $ORARIO_FINE_INPUT | awk '{ print $3 }')

if [ $GIORNO_START = $GIORNO_END ] ; then
   GIORNO=$GIORNO_START
else
  echo "$(time_stamp) --> Estrazione non dello stesso giorno, si considera il giorno finale"
  GIORNO=$GIORNO_END
fi

FILE_LOG=/tmp/nconn_$GIORNO.txt

MESE=$(echo $ORARIO_FINE_INPUT | awk '{ print $1 }')
trasforma_mese_letter2num
MESE=$MESE_NUM

echo  "$(time_stamp) --> Estrazione da $FILE_LOG"


ORA=$ORA_START
ORA=$(expr $ORA + 1 - 1 )
if [ $ORA -le 9 ]; then
    ORA=0$ORA
fi
if [ $ORA -eq 0 ]; then
    ORA=00
fi

STRINGA="$GIORNO-$MESE-$ANNO $ORA"

grep ^"$STRINGA" $FILE_LOG > $DIR_APPOGGIO/$HOSTNAME.nconn

ORA=$(expr $ORA + 1 - 1 )
ORA_END=$(expr $ORA_END + 1 - 1 )

while [[ $ORA -lt $ORA_END ]] ; do
	ORA=$(expr $ORA + 1 )
	if [ $ORA -le 9 ]; then
      ORA=0$ORA
  fi
  if [ $ORA -eq 0 ]; then
    ORA=00
  fi
  STRINGA="$GIORNO-$MESE-$ANNO $ORA"
  grep ^"$STRINGA" $FILE_LOG >> $DIR_APPOGGIO/$HOSTNAME.nconn
done

}
#######################################################################################################
# Collect file outbound e inbound
# Naming convention:  outbound.log.2 outbound.log.23
#                     outbound.log.<giorno>
# Eccezione per lo 0, che è l'ultimo giorno del mese precedente
# Il log del giorno non ha il numero finale
#
outbound(){

TODAY=$(date +"%h %d")

# Prendiamo i file del giorno finale se i giorni sono diversi
GIORNO_START=$(echo $ORARIO_INIZIO_INPUT | awk '{ print $2 }')
GIORNO_END=$(echo $ORARIO_FINE_INPUT | awk '{ print $2 }')
ORA_START=$(echo $ORARIO_INIZIO_INPUT | awk '{ print $3 }')
ORA_END=$(echo $ORARIO_FINE_INPUT | awk '{ print $3 }')

if [ $GIORNO_START = $GIORNO_END ] ; then
   GIORNO=$GIORNO_START
else
  echo "$(time_stamp) --> Estrazione non dello stesso giorno, si considera il giorno finale"
  GIORNO=$GIORNO_END
fi

# Tolgo lo zero iniziale

ANNO=$(date +%Y)
MESE=$(echo $ORARIO_FINE_INPUT | awk '{ print $1 }')
MESE_GIORNO="$MESE $GIORNO"
GIORNO=$(expr $GIORNO + 1 - 1 )

#echo "$TODAY"
#echo "$MESE_GIORNO"

if [ "$TODAY" = "$MESE_GIORNO" ] ; then
    FILE_OUTBOUND=/tmp/outbound.log
    FILE_INBOUND=/tmp/inbound.log
else
      if [ $GIORNO = 31 ]; then
          GIORNO_FILE=0
      fi

      if [ $GIORNO = 30 ]; then
         if [ $MESE = "Apr"|$MESE ="Jun"|$MESE ="Sep"|$MESE ="Nov" ] ; then
          GIORNO_FILE=0
         else
          GIORNO_FILE=$GIORNO
         fi
      fi

      if [ $GIORNO = 29 ]; then
         if [ $MESE = "Feb" ] ; then
          GIORNO_FILE=0
         else
          GIORNO_FILE=$GIORNO
         fi
      fi

      if [ $GIORNO = 28 ]; then
         if [ $MESE = "Feb" ] ; then
           if [ $ANNO = 2012 ] ; then
              GIORNO_FILE=$GIORNO
             else
              GIORNO_FILE=0
          fi
         fi
      fi

      if [ $GIORNO -lt 28 ]; then
         GIORNO_FILE=$GIORNO
      fi
      FILE_OUTBOUND=/tmp/outbound.log.$GIORNO_FILE
      FILE_INBOUND=/tmp/inbound.log.$GIORNO_FILE
fi

echo  "$(time_stamp) --> Estrazione outbound da $FILE_OUTBOUND e inbound da $FILE_INBOUND"

ORA=$ORA_START
ORA=$(expr $ORA + 1 - 1 )
if [ $ORA -le 9 ]; then
    ORA=0$ORA
fi

grep ^$ORA $FILE_OUTBOUND > $DIR_APPOGGIO/$HOSTNAME.outbound
grep ^$ORA $FILE_INBOUND > $DIR_APPOGGIO/$HOSTNAME.inbound

ORA=$(expr $ORA + 1 - 1 )
ORA_END=$(expr $ORA_END + 1 - 1 )

while [[ $ORA -lt $ORA_END ]] ; do
	ORA=$(expr $ORA + 1 )
	if [ $ORA -le 9 ]; then
      ORA=0$ORA
  fi
  grep ^$ORA $FILE_OUTBOUND >> $DIR_APPOGGIO/$HOSTNAME.outbound
  grep ^$ORA $FILE_INBOUND >> $DIR_APPOGGIO/$HOSTNAME.inbound
done

}
#######################################################################################################
trasforma_orario_db2lock(){

# Trasforma orario di input in formato db2locktimeout
# db2locktimeout.0.1003.2011-05-04-15-03-18

ANNO=$(date +%Y)
MESE=$1
GIORNO=$2
ORA=$3

# Ritorna MESE_NUM
trasforma_mese_letter2num

echo .$ANNO-$MESE_NUM-$GIORNO-$ORA-

}
#######################################################################################################
trasforma_mese_letter2num(){

case "$MESE" in
        Jan)
          MESE_NUM=01
          ;;
        Feb)
          MESE_NUM=02
          ;;
        Mar)
          MESE_NUM=03
          ;;
        Apr)
          MESE_NUM=04
          ;;
        May)
          MESE_NUM=05
          ;;
        Jun)
          MESE_NUM=06
          ;;
        Jul)
          MESE_NUM=07
          ;;
        Aug)
          MESE_NUM=08
          ;;
        Sep)
          MESE_NUM=09
          ;;
        Oct)
          MESE_NUM=10
          ;;
        Nov)
          MESE_NUM=11
          ;;
        Dec)
          MESE_NUM=12
          ;;
        *)
            echo  "$(time_stamp) --> Mese $MESE non valido"
            exit 1
esac

}
#######################################################################################################
javacore(){
# Collect dei file javacore
# javacore.20110516.174104.160012.0001.txt

# Creo la lista dei file
find $DIR_LOG -name javacore.* > $DIR_APPOGGIO/javacore.lista_tmp

# Prendiamo i file del giorno finale se i giorni sono diversi
GIORNO_START=$(echo $ORARIO_INIZIO_INPUT | awk '{ print $2 }')
GIORNO_END=$(echo $ORARIO_FINE_INPUT | awk '{ print $2 }')
if [ $GIORNO_START = $GIORNO_END ] ; then
   GIORNO=$GIORNO_START
else
  echo "$(time_stamp) --> Estrazione non dello stesso giorno, si considera il giorno finale"
   GIORNO=$GIORNO_END
fi

ORA_START=$(echo $ORARIO_INIZIO_INPUT | awk '{ print $3 }')
ORA_END=$(echo $ORARIO_FINE_INPUT | awk '{ print $3 }')

ANNO=$(date +%Y)
MESE=$(echo $ORARIO_INIZIO_INPUT | awk '{ print $1 }')
trasforma_mese_letter2num

ORA=$ORA_START
grep .$ANNO$MESE_NUM$GIORNO.$ORA  $DIR_APPOGGIO/javacore.lista_tmp > $DIR_APPOGGIO/javacore.lista

while [[ $ORA -lt $ORA_END ]] ; do
	ORA=$(expr $ORA + 1 )
	if [ $ORA -le 9 ]; then
      ORA=0$ORA
  fi
  grep .$ANNO$MESE_NUM$GIORNO.$ORA  $DIR_APPOGGIO/javacore.lista_tmp >> $DIR_APPOGGIO/javacore.lista
done


if [ -s "$DIR_APPOGGIO/javacore.lista" ]; then
  CUR_DIR=$(pwd)
  awk -F\/ '{ print $7 }' $DIR_APPOGGIO/javacore.lista | sort | uniq | while read AS
  do
    cd  $DIR_LOG/$AS
    grep $AS $DIR_APPOGGIO/javacore.lista | awk -F\/ '{ print $8 }' | xargs tar -cvf - | gzip > $DIR_APPOGGIO/$HOSTNAME.$AS.javacore.tgz
  done
  cd $CUR_DIR
fi
rm -f $DIR_APPOGGIO/javacore.list*

}
#######################################################################################################
db2locktimeout(){
# Dato l'alto numero di file molti comandi danno l'errore: arg list too long

# Creo la lista dei file
ls -l $DIR_DB2LOCKTIMEOUT | grep ^- | awk '{print $9}' | grep db2locktimeout.0. > $DIR_APPOGGIO/db2locktimeout.lista_tmp

# Prendiamo i file del giorno finale se i giorni sono diversi
GIORNO_START=$(echo $ORARIO_INIZIO_INPUT | awk '{ print $2 }')
GIORNO_END=$(echo $ORARIO_FINE_INPUT | awk '{ print $2 }')
if [ $GIORNO_START = $GIORNO_END ] ; then
   GIORNO=$GIORNO_START
else
  echo "$(time_stamp) --> Estrazione non dello stesso giorno, si considera il giorno finale"
fi

ORA_START=$(echo $ORARIO_INIZIO_INPUT | awk '{ print $3 }')
ORA_END=$(echo $ORARIO_FINE_INPUT | awk '{ print $3 }')

ANNO=$(date +%Y)
MESE=$(echo $ORARIO_INIZIO_INPUT | awk '{ print $1 }')
trasforma_mese_letter2num

ORA=$ORA_START
#echo .$ANNO-$MESE_NUM-$GIORNO-$ORA-
grep .$ANNO-$MESE_NUM-$GIORNO-$ORA-  $DIR_APPOGGIO/db2locktimeout.lista_tmp > $DIR_APPOGGIO/$HOSTNAME.db2locktimeout.lista

while [[ $ORA -lt $ORA_END ]] ; do
	ORA=$(expr $ORA + 1 )
	if [ $ORA -le 9 ]; then
      ORA=0$ORA
  fi
  #echo .$ANNO-$MESE_NUM-$GIORNO-$ORA-
	grep .$ANNO-$MESE_NUM-$GIORNO-$ORA-  $DIR_APPOGGIO/db2locktimeout.lista_tmp >> $DIR_APPOGGIO/$HOSTNAME.db2locktimeout.lista
done

# Creazione tgz con i primi 20 file

COUNT_DB2LOCK=$(wc -l $DIR_APPOGGIO/$HOSTNAME.db2locktimeout.lista | awk '{ print $1 }')
if [ $COUNT_DB2LOCK = 0 ]; then
    echo "$(time_stamp) --> File db2locktimeout non presenti"
else
    echo "$(time_stamp) --> Presenti $COUNT_DB2LOCK file db2locktimeout"
    echo "$(time_stamp) --> Creazione tgz con max i primi 20 file"
    cd $DIR_DB2LOCKTIMEOUT
    cat $DIR_APPOGGIO/$HOSTNAME.db2locktimeout.lista | head -20 | xargs tar -cvf - | /usr/contrib/bin/gzip > $DIR_APPOGGIO/$HOSTNAME.db2locktimeout_log.tgz
    cd - > /dev/null 2>&1
fi
rm -f $DIR_APPOGGIO/db2locktimeout.lista_tmp

}
#######################################################################################################
extract_db2diag(){
# Estrazione db2diag
echo "$(time_stamp) --> Esecuzione db2profile"
#. ~/.prof
. /home/db2isdp1/sqllib/db2profile

ANNO=$(date +%Y)
MESE=$(echo $ORARIO_INIZIO_INPUT | awk '{ print $1 }')
trasforma_mese_letter2num
# Il mese è in MESE_NUM

GIORNO_START=$(echo $ORARIO_INIZIO_INPUT | awk '{ print $2 }')
GIORNO_END=$(echo $ORARIO_FINE_INPUT | awk '{ print $2 }')

ORA_START=$(echo $ORARIO_INIZIO_INPUT | awk '{ print $3 }')
ORA_END=$(echo $ORARIO_FINE_INPUT | awk '{ print $3 }')

cd /home/db2isdp1/sqllib/db2dump

echo "$(time_stamp) --> Esecuzione db2diag"
/home/db2isdp1/sqllib/bin/db2diag -readfile -time "$ANNO-$MESE_NUM-$GIORNO_START-$ORA_START.00:$ANNO-$MESE_NUM-$GIORNO_END-$ORA_END.59" > $DIR_APPOGGIO/$HOSTNAME.db2diag.log

cd - 2> /dev/null

}
#######################################################################################################
trasforma_orario(){

# Trasforma orario di input in formato systemOut
# attenzione all'ora minore di 10
# Range ora [0-23]
# Chiusura con il punto
#[30/04/11 9.


ANNO=$(date +%y)
MESE=$1
GIORNO=$2
ORA=$3

trasforma_mese_letter2num

#Tolgo l'eventuale 0 per le ore -lt 10

ORA=$(expr $ORA + 1 - 1 )

# Formato log GIORNO/MESE/ANNO ORA.
#echo "$GIORNO/$MESE_NUM/$ANNO $ORA."
echo "$GIORNO\/$MESE_NUM\/$ANNO $ORA."

}
#######################################################################################################
NPARAM=$#

HOSTNAME=$(hostname)
INIZIO=$(echo $2 | tr ' ' '.' )
FINE=$(echo $3 | tr ' ' '.' )
RANGE_ORARIO=$INIZIO-$FINE

# Caricamento file properties
if [ -a ~/bin/override.properties ] ; then
  echo "$(time_stamp) --> Override parametri"
	. ~/bin/override.properties
  #echo $DIR_APPOGGIO
fi

# Crea directory di appoggio
mkdir -p $DIR_APPOGGIO

case "$1" in
          -e)
               MINARG=3
               check_argv
               ORARIO_INIZIO_INPUT=$2
               ORARIO_FINE_INPUT=$3
               echo "$(time_stamp) --> Inizio Esecuzione Comando: $0 $1 \"$2\" \"$3\" "
               # Controllo formale dati di input
               check_orario $ORARIO_INIZIO_INPUT
               check_orario $ORARIO_FINE_INPUT
               lista_log native_stderr.log
               TIME_FORMAT="native"
               for FILE_LOG in $LISTA_LOG
               do
                    # Calcolo righe log
                    RIGHE_LOG=$(wc -l $FILE_LOG | awk '{ print $1 }')
                    # Partenza con i dati di input
                    ORARIO_INIZIO=$ORARIO_INIZIO_INPUT
                    ORARIO_FINE=$ORARIO_FINE_INPUT
                    FILE_OUT=$(echo $FILE_LOG | awk -F/ '{ print $7 "."  $9 "." $10 }')
                    echo  "$(time_stamp) --> Estrazione file $FILE_OUT"
                    # Formato data numerica per verifica range
                    # 2010110711049049
                    # AAAAMMGGHH0mm0ss
                    range_log_native
                    ORARIO_INIZIO_NUM=$(native2range $ORARIO_INIZIO)
                    ORARIO_INIZIO_NUM="$ORARIO_INIZIO_NUM"000000
                    #echo $NUM_ORARIO_INIZIO
                    echo  "$(time_stamp) --> Check Orario inizio $ORARIO_INIZIO"

                    if [ $ORARIO_INIZIO_NUM -lt $DATA_INIZIO_LOG ]; then
                         NUM_RIGA_INIZIO=1
                         echo  "$(time_stamp) --> Data inizio non nel log. Num riga:1"
                    elif [ $ORARIO_INIZIO_NUM -gt $DATA_FINE_LOG ]; then
                         NUM_RIGA_INIZIO=$RIGHE_LOG
                         echo  "$(time_stamp) --> Data inizio non nel log. Num riga:$NUM_RIGA_INIZIO"
                    else
                          check_orario_inizio
                    fi
                    ORARIO_INIZIO=$ORARIO_INIZIO_INPUT
                    ORARIO_FINE_NUM=$(native2range $ORARIO_FINE)
                    ORARIO_FINE_NUM="$ORARIO_FINE_NUM"059059
                    #echo $NUM_ORARIO_FINE
                    echo  "$(time_stamp) --> Check Orario fine $ORARIO_FINE"

                    if [ $ORARIO_FINE_NUM -lt $DATA_INIZIO_LOG ]; then
                         NUM_RIGA_FINE=1
                         echo  "$(time_stamp) --> Data fine non nel log. Num riga:1"
                    elif [ $ORARIO_FINE_NUM -gt $DATA_FINE_LOG ]; then
                         NUM_RIGA_FINE=$RIGHE_LOG
                         echo  "$(time_stamp) --> Data fine non nel log. Num riga:$NUM_RIGA_FINE"
                    else
                        check_orario_fine
                    fi

                    echo  "$(time_stamp) --> Estrazione log"
                    estrae_log
               done
               #echo  "$(time_stamp) --> Creazione file tar.gz"
               #packaging native_stderr.log
               echo "$(time_stamp) --> Fine Esecuzione Comando"
           ;;
          -p)
                MINARG=3
                check_argv
                ORARIO_INIZIO_INPUT=$2
                ORARIO_FINE_INPUT=$3
                echo "$(time_stamp) --> Inizio Esecuzione Comando: $0 $1 \"$2\" \"$3\" "
                # Controllo formale dati di input
                check_orario $ORARIO_INIZIO_INPUT
                check_orario $ORARIO_FINE_INPUT
                ORARIO_INIZIO=$(trasforma_orario_http $ORARIO_INIZIO_INPUT)
                ORARIO_FINE=$(trasforma_orario_http $ORARIO_FINE_INPUT)
                # Copia orario input per i file successivi
                ORARIO_INIZIO_INPUT=$ORARIO_INIZIO
                ORARIO_FINE_INPUT=$ORARIO_FINE
                #echo $ORARIO_INIZIO_INPUT $ORARIO_FINE_INPUT
                echo  "$(time_stamp) --> Estrazione perf_log http"
                lista_log_http  perf_log
                TIME_FORMAT="http"
               for FILE_LOG in $LISTA_LOG
               do
                    # Calcolo righe log
                    RIGHE_LOG=$(wc -l $FILE_LOG | awk '{ print $1 }')
                    # Partenza con i dati di input trasformati
                    ORARIO_INIZIO=$ORARIO_INIZIO_INPUT
                    ORARIO_FINE=$ORARIO_FINE_INPUT
                    FILE_OUT=$(echo $FILE_LOG | awk -F/ '{ print $6 "."  $8 }')
                    SERVER_NAME=$(echo $FILE_LOG | awk -F/ '{ print $6 }')
                    FILE_OUT=$HOSTNAME.$FILE_OUT
                    echo  "$(time_stamp) --> Estrazione file $FILE_OUT"
                    range_perflog_http

                    ORARIO_INIZIO_NUM=$(http2range $ORARIO_INIZIO)
                    ORARIO_INIZIO_NUM="$ORARIO_INIZIO_NUM"00
                    #echo $ORARIO_INIZIO_NUM
                    echo  "$(time_stamp) --> Check Orario inizio $ORARIO_INIZIO"

                    if [ $ORARIO_INIZIO_NUM -lt $DATA_INIZIO_LOG ]; then
                         NUM_RIGA_INIZIO=1
                         echo  "$(time_stamp) --> Data inizio non nel log. Num riga:1"
                    elif [ $ORARIO_INIZIO_NUM -gt $DATA_FINE_LOG ]; then
                         NUM_RIGA_INIZIO=$RIGHE_LOG
                         echo  "$(time_stamp) --> Data inizio non nel log. Num riga:$NUM_RIGA_INIZIO"
                    else
                          check_orario_inizio
                    fi

                    ORARIO_FINE_NUM=$(http2range $ORARIO_FINE)
                    ORARIO_FINE_NUM="$ORARIO_FINE_NUM"59
                    #echo $ORARIO_FINE_NUM
                    echo  "$(time_stamp) --> Check Orario fine $ORARIO_FINE"

                    ORARIO_INIZIO=$ORARIO_INIZIO_INPUT

                    if [ $ORARIO_FINE_NUM -lt $DATA_INIZIO_LOG ]; then
                         NUM_RIGA_FINE=1
                         echo  "$(time_stamp) --> Data fine non nel log. Num riga:1"
                    elif [ $ORARIO_FINE_NUM -gt $DATA_FINE_LOG ]; then
                         NUM_RIGA_FINE=$RIGHE_LOG
                         echo  "$(time_stamp) --> Data fine non nel log. Num riga:$NUM_RIGA_FINE"
                    else
                        check_orario_fine
                    fi

                    echo  "$(time_stamp) --> Estrazione log"
                    estrae_log
                    make_pivot
               done
                echo  "$(time_stamp) --> Estrazione error_log http"
                lista_log_http  error_log
                TIME_FORMAT="http"
               for FILE_LOG in $LISTA_LOG
               do
                    # Calcolo righe log
                    RIGHE_LOG=$(wc -l $FILE_LOG | awk '{ print $1 }')
                    # Partenza con i dati di input
                    ORARIO_INIZIO=$ORARIO_INIZIO_INPUT
                    ORARIO_FINE=$ORARIO_FINE_INPUT
                    FILE_OUT=$(echo $FILE_LOG | awk -F/ '{ print $6 "."  $8 }')
                    SERVER_NAME=$(echo $FILE_LOG | awk -F/ '{ print $6 }')
                    FILE_OUT=$HOSTNAME.$FILE_OUT
                    echo  "$(time_stamp) --> Estrazione file $FILE_OUT"
                    range_log_http

                    ORARIO_INIZIO_NUM=$(http2range $ORARIO_INIZIO)
                    ORARIO_INIZIO_NUM="$ORARIO_INIZIO_NUM"00
                    #echo $ORARIO_INIZIO_NUM
                    echo  "$(time_stamp) --> Check Orario inizio $ORARIO_INIZIO"

                    if [ $ORARIO_INIZIO_NUM -lt $DATA_INIZIO_LOG ]; then
                         NUM_RIGA_INIZIO=1
                         echo  "$(time_stamp) --> Data inizio non nel log. Num riga:1"
                    elif [ $ORARIO_INIZIO_NUM -gt $DATA_FINE_LOG ]; then
                         NUM_RIGA_INIZIO=$RIGHE_LOG
                         echo  "$(time_stamp) --> Data inizio non nel log. Num riga:$NUM_RIGA_INIZIO"
                    else
                          check_orario_inizio
                    fi

                    ORARIO_INIZIO=$ORARIO_INIZIO_INPUT

                    ORARIO_FINE_NUM=$(http2range $ORARIO_FINE)
                    ORARIO_FINE_NUM="$ORARIO_FINE_NUM"59
                    #echo $ORARIO_FINE_NUM
                    echo  "$(time_stamp) --> Check Orario fine $ORARIO_FINE"

                    if [ $ORARIO_FINE_NUM -lt $DATA_INIZIO_LOG ]; then
                         NUM_RIGA_FINE=1
                         echo  "$(time_stamp) --> Data fine non nel log. Num riga:1"
                    elif [ $ORARIO_FINE_NUM -gt $DATA_FINE_LOG ]; then
                         NUM_RIGA_FINE=$RIGHE_LOG
                         echo  "$(time_stamp) --> Data fine non nel log. Num riga:$NUM_RIGA_FINE"
                    else
                        check_orario_fine
                    fi

                    echo  "$(time_stamp) --> Estrazione log"
                    estrae_log
               done

               #echo  "$(time_stamp) --> Creazione file tar.gz"
               #packaging  perf_log
               echo "$(time_stamp) --> Fine Esecuzione Comando"

          ;;
          -s)
                # Estrazione systemout.log
                MINARG=3
                check_argv
                ORARIO_INIZIO_INPUT=$2
                ORARIO_FINE_INPUT=$3
                echo "$(time_stamp) --> Inizio Esecuzione Comando: $0 $1 \"$2\" \"$3\" "
                # Controllo formale dati di input
                check_orario $ORARIO_INIZIO_INPUT
                check_orario $ORARIO_FINE_INPUT
                ORARIO_INIZIO=$(trasforma_orario $ORARIO_INIZIO_INPUT)
                ORARIO_FINE=$(trasforma_orario $ORARIO_FINE_INPUT)
                # Copia orario input per i file successivi
                ORARIO_INIZIO_INPUT=$ORARIO_INIZIO
                ORARIO_FINE_INPUT=$ORARIO_FINE
                echo  "$(time_stamp) --> Estrazione da SystemOut.log"
                lista_log SystemOut.log
                TIME_FORMAT="systemout"
                for FILE_LOG in $LISTA_LOG
                do
                    # Calcolo righe log
                    RIGHE_LOG=$(wc -l $FILE_LOG | awk '{ print $1 }')
                    # Partenza con i dati di input
                    ORARIO_INIZIO=$ORARIO_INIZIO_INPUT
                    ORARIO_FINE=$ORARIO_FINE_INPUT
                    FILE_OUT=$(echo $FILE_LOG | awk -F/ '{ print $7 "."  $9 "." $10 }')
                    # Calcolo range del file di log
                    range_log
                    echo  "$(time_stamp) --> Estrazione file $FILE_OUT"
                    echo  "$(time_stamp) --> Check Orario inizio $ORARIO_INIZIO"
                    ORA=$(echo $ORARIO_INIZIO | awk '{ print $2}')
                    ORA=$(echo $ORA | awk -F. '{ print $1 }')
                    if [ $ORA -lt 10 ]; then
                         ORA=0$ORA
                    fi
                    ORARIO_INIZIO_NUM=$(echo $ORARIO_INIZIO | tr '\\' ' ' | tr '/' ' ' | awk '{ print $3 $2 $1 }')
                    ORARIO_INIZIO_NUM=$ORARIO_INIZIO_NUM$ORA
                    if [ $ORARIO_INIZIO_NUM -lt $DATA_INIZIO_LOG ]; then
                         NUM_RIGA_INIZIO=1
                         echo  "$(time_stamp) --> Data inizio non nel log. Num riga:1"
                    elif [ $ORARIO_INIZIO_NUM -gt $DATA_FINE_LOG ]; then
                         NUM_RIGA_INIZIO=$RIGHE_LOG
                         echo  "$(time_stamp) --> Data inizio non nel log. Num riga:$NUM_RIGA_INIZIO"
                    else
                          check_orario_inizio
                    fi

                    ORARIO_INIZIO=$ORARIO_INIZIO_INPUT

                    echo  "$(time_stamp) --> Check Orario fine $ORARIO_FINE"
                    ORA=$(echo $ORARIO_FINE | awk '{ print $2}')
                    ORA=$(echo $ORA | awk -F. '{ print $1 }')
                    if [ $ORA -lt 10 ]; then
                         ORA=0$ORA
                    fi
                    ORARIO_FINE_NUM=$(echo $ORARIO_FINE | tr '\\' ' ' | tr '/' ' ' | awk '{ print $3 $2 $1 }')
                    ORARIO_FINE_NUM=$ORARIO_FINE_NUM$ORA
                    if [ $ORARIO_FINE_NUM -lt $DATA_INIZIO_LOG ]; then
                         NUM_RIGA_FINE=1
                         echo  "$(time_stamp) --> Data fine non nel log. Num riga:1"
                    elif [ $ORARIO_FINE_NUM -gt $DATA_FINE_LOG ]; then
                         NUM_RIGA_FINE=$RIGHE_LOG
                         echo  "$(time_stamp) --> Data fine non nel log. Num riga:$NUM_RIGA_FINE"
                    else
                        check_orario_fine
                    fi
                    estrae_log
                    trasforma_sysout
                done
                echo  "$(time_stamp) --> Creazione file tar.gz"
                #packaging SystemOut.log
                echo "$(time_stamp) --> Fine Esecuzione Comando"
            ;;
            -a)
                # Estrazione sar
                MINARG=3
                check_argv
                ORARIO_INIZIO_INPUT=$2
                ORARIO_FINE_INPUT=$3
                echo "$(time_stamp) --> Inizio Esecuzione Comando: $0 $1 \"$2\" \"$3\" "
                # Controllo formale dati di input
                check_orario $ORARIO_INIZIO_INPUT
                check_orario $ORARIO_FINE_INPUT
                PLATFORM=$(uname)
                echo  "$(time_stamp) --> Estrazione Sar CPU"
                create_sar_cpu
                echo "$(time_stamp) --> Fine Esecuzione Comando"
            ;;
            -P)
                # Estrazione sar
                MINARG=3
                check_argv
                ORARIO_INIZIO_INPUT=$2
                ORARIO_FINE_INPUT=$3
                echo "$(time_stamp) --> Inizio Esecuzione Comando: $0 $1 \"$2\" \"$3\" "
                # Controllo formale dati di input
                check_orario $ORARIO_INIZIO_INPUT
                check_orario $ORARIO_FINE_INPUT
                PLATFORM=$(uname)
                echo  "$(time_stamp) --> Estrazione Sar -P all"
                create_sar
                echo "$(time_stamp) --> Fine Esecuzione Comando"
            ;;
            -k)
                # Estrazione sar
                MINARG=3
                check_argv
                ORARIO_INIZIO_INPUT=$2
                ORARIO_FINE_INPUT=$3
                echo "$(time_stamp) --> Inizio Esecuzione Comando: $0 $1 \"$2\" \"$3\" "
                # Controllo formale dati di input
                check_orario $ORARIO_INIZIO_INPUT
                check_orario $ORARIO_FINE_INPUT
                PLATFORM=$(uname)
                echo  "$(time_stamp) --> Estrazione Sar disk"
                create_sar_disk
                echo "$(time_stamp) --> Fine Esecuzione Comando"
            ;;
            -o)
                # Collect dei file outbound.log
                MINARG=3
                check_argv
                ORARIO_INIZIO_INPUT=$2
                ORARIO_FINE_INPUT=$3
                echo "$(time_stamp) --> Inizio Esecuzione Comando: $0 $1 \"$2\" \"$3\" "
                # Controllo formale dati di input
                check_orario $ORARIO_INIZIO_INPUT
                check_orario $ORARIO_FINE_INPUT
                PLATFORM=$(uname)
                echo  "$(time_stamp) --> Collect outbound.log e inbound.log"
                outbound
                echo "$(time_stamp) --> Fine Esecuzione Comando"
            ;;
            -S)
                # Collect dei file snap
                MINARG=3
                check_argv
                ORARIO_INIZIO_INPUT=$2
                ORARIO_FINE_INPUT=$3
                echo "$(time_stamp) --> Inizio Esecuzione Comando: $0 $1 \"$2\" \"$3\" "
                # Controllo formale dati di input
                check_orario $ORARIO_INIZIO_INPUT
                check_orario $ORARIO_FINE_INPUT
                PLATFORM=$(uname)
                echo  "$(time_stamp) --> Collect dbmsnap"
                dbmsnap
                echo "$(time_stamp) --> Fine Esecuzione Comando"
            ;;
            -l)
                # Collect db2locktimeout
                MINARG=3
                check_argv
                ORARIO_INIZIO_INPUT=$2
                ORARIO_FINE_INPUT=$3
                echo "$(time_stamp) --> Inizio Esecuzione Comando: $0 $1 \"$2\" \"$3\" "
                # Controllo formale dati di input
                check_orario $ORARIO_INIZIO_INPUT
                check_orario $ORARIO_FINE_INPUT
                #ORARIO_INIZIO=$(trasforma_orario_db2lock $ORARIO_INIZIO_INPUT)
                #ORARIO_FINE=$(trasforma_orario_db2lock $ORARIO_FINE_INPUT)
                # Copia orario input per i file successivi
                echo "$(time_stamp) --> Collect db2locktimeout"
                #echo $ORARIO_INIZIO $ORARIO_FINE
                db2locktimeout
                echo "$(time_stamp) --> Fine Esecuzione Comando"
            ;;
            -d)
                # Estrazione db2diag
                MINARG=3
                check_argv
                ORARIO_INIZIO_INPUT=$2
                ORARIO_FINE_INPUT=$3
                echo "$(time_stamp) --> Inizio Esecuzione Comando: $0 $1 \"$2\" \"$3\" "
                # Controllo formale dati di input
                check_orario $ORARIO_INIZIO_INPUT
                check_orario $ORARIO_FINE_INPUT
                echo "$(time_stamp) --> Estrazione db2diag"
                extract_db2diag
                echo "$(time_stamp) --> Fine Esecuzione Comando"
            ;;
            -j)
                # Collect dei javacore
                MINARG=3
                check_argv
                ORARIO_INIZIO_INPUT=$2
                ORARIO_FINE_INPUT=$3
                echo "$(time_stamp) --> Inizio Esecuzione Comando: $0 $1 \"$2\" \"$3\" "
                # Controllo formale dati di input
                check_orario $ORARIO_INIZIO_INPUT
                check_orario $ORARIO_FINE_INPUT
                echo "$(time_stamp) --> Collect javacore"
                javacore
                echo "$(time_stamp) --> Fine Esecuzione Comando"
            ;;
            -t)
                # Collect check_HTTP.txt
                MINARG=3
                check_argv
                ORARIO_INIZIO_INPUT=$2
                ORARIO_FINE_INPUT=$3
                echo "$(time_stamp) --> Inizio Esecuzione Comando: $0 $1 \"$2\" \"$3\" "
                # Controllo formale dati di input
                check_orario $ORARIO_INIZIO_INPUT
                check_orario $ORARIO_FINE_INPUT
                echo "$(time_stamp) --> Collect check_HTTP.txt"
                collect_check_HTTP
                echo "$(time_stamp) --> Fine Esecuzione Comando"
            ;;
            -c) #
                # Clean directory
                echo "$(time_stamp) --> Inizio Esecuzione Comando: $0 $1 \"$2\" \"$3\" "
                echo "$(time_stamp) --> Clean directory appoggio"
                rm -f $DIR_APPOGGIO/*
                echo "$(time_stamp) --> Fine Esecuzione Comando"
            ;;
            -r)
                # Estrazione contatori HADR
                MINARG=3
                check_argv
                ORARIO_INIZIO_INPUT=$2
                ORARIO_FINE_INPUT=$3
                echo "$(time_stamp) --> Inizio Esecuzione Comando: $0 $1 \"$2\" \"$3\" "
                # Controllo formale dati di input
                check_orario $ORARIO_INIZIO_INPUT
                check_orario $ORARIO_FINE_INPUT
                echo "$(time_stamp) --> Estrazione contatori HADR"
                check_giorno
                FILE_LOG=$DIR_HADR/$LOG_HADR-$GG_FILE.csv
                if [ -a $FILE_LOG ]; then
                    # Calcolo righe log
                    RIGHE_LOG=$(wc -l $FILE_LOG | awk '{ print $1 }')
                    # Partenza con i dati di input
                    ORARIO_INIZIO=$(native2hadr $ORARIO_INIZIO_INPUT)
                    ORARIO_FINE=$(native2hadr $ORARIO_FINE_INPUT)
                    FILE_OUT=$HOSTNAME.$LOG_HADR.csv
                    echo  "$(time_stamp) --> Estrazione file $FILE_OUT"
                    # Formato data numerica per verifica range
                    # 20101107114949
                    # AAAAMMGGHHmmss
                    range_log_hadr

                    TIME_FORMAT="hadr"

                    ORARIO_INIZIO_NUM=$(native2range $ORARIO_INIZIO_INPUT)
                    ORARIO_INIZIO_NUM="$ORARIO_INIZIO_NUM"0000
                    #echo $ORARIO_INIZIO_NUM
                    echo  "$(time_stamp) --> Check Orario inizio $ORARIO_INIZIO"
                    #echo $DATA_INIZIO_LOG $DATA_FINE_LOG
                    if [ $ORARIO_INIZIO_NUM -lt $DATA_INIZIO_LOG ]; then
                         NUM_RIGA_INIZIO=1
                         echo  "$(time_stamp) --> Data inizio non nel log. Num riga:1"
                    elif [ $ORARIO_INIZIO_NUM -gt $DATA_FINE_LOG ]; then
                         NUM_RIGA_INIZIO=$RIGHE_LOG
                         echo  "$(time_stamp) --> Data inizio non nel log. Num riga:$NUM_RIGA_INIZIO"
                    else
                          check_orario_inizio
                    fi

                    ORARIO_INIZIO=$(native2hadr $ORARIO_INIZIO_INPUT)

                    ORARIO_FINE_NUM=$(native2range $ORARIO_FINE_INPUT)
                    ORARIO_FINE_NUM="$ORARIO_FINE_NUM"5959
                    #echo $ORARIO_FINE_NUM
                    echo  "$(time_stamp) --> Check Orario fine $ORARIO_FINE"

                    if [ $ORARIO_FINE_NUM -lt $DATA_INIZIO_LOG ]; then
                         NUM_RIGA_FINE=1
                         echo  "$(time_stamp) --> Data fine non nel log. Num riga:1"
                    elif [ $ORARIO_FINE_NUM -gt $DATA_FINE_LOG ]; then
                         NUM_RIGA_FINE=$RIGHE_LOG
                         echo  "$(time_stamp) --> Data fine non nel log. Num riga:$NUM_RIGA_FINE"
                    else
                        check_orario_fine
                    fi

                    echo  "$(time_stamp) --> Estrazione log"
                    estrae_log
                else
                   echo  "$(time_stamp) --> File $FILE_LOG inesistente"
                fi
                echo "$(time_stamp) --> Fine Esecuzione Comando"
            ;;
            -m)
                #Estrazione Log Montini
                MINARG=3
                check_argv
                ORARIO_INIZIO_INPUT=$2
                ORARIO_FINE_INPUT=$3
                echo "$(time_stamp) --> Inizio Esecuzione Comando: $0 $1 \"$2\" \"$3\" "
                # Controllo formale dati di input
                check_orario $ORARIO_INIZIO_INPUT
                check_orario $ORARIO_FINE_INPUT

                echo "$(time_stamp) --> Estrazione log Montini"

                TIME_FORMAT="montini"

                for FILE_LOG in $LOG_INDOUBT $LOG_FIRSTLSN
                do
                    # Calcolo righe log
                    RIGHE_LOG=$(wc -l $FILE_LOG | awk '{ print $1 }')
                    # Partenza con i dati di input
                    ORARIO_INIZIO=$ORARIO_INIZIO_INPUT
                    ORARIO_FINE=$ORARIO_FINE_INPUT
                    FILE_OUT=$(echo $FILE_LOG | awk -F/ '{ print $6 }')
                    FILE_OUT=$HOSTNAME.$FILE_OUT
                    # Calcolo range del file di log
                    range_log_montini
                    #echo $DATA_INIZIO_LOG  $DATA_FINE_LOG
                    echo  "$(time_stamp) --> Estrazione da file $FILE_LOG"
                    echo  "$(time_stamp) --> Check Orario inizio $ORARIO_INIZIO"
                    ORARIO_INIZIO_NUM=$(native2range $ORARIO_INIZIO)
                    ORARIO_INIZIO_NUM=$ORARIO_INIZIO_NUM"00"
                    native2montini $ORARIO_INIZIO_INPUT
                    GIORNO=$(expr $GIORNO + 1 - 1 )
                    if [ $GIORNO -le 9 ]; then
                      ORARIO_INIZIO="$MESE  $GIORNO $ORA"
                    else
                      ORARIO_INIZIO="$MESE $GIORNO $ORA"
                    fi
                    # echo  $ORARIO_INIZIO_NUM
                    # echo  $ORARIO_INIZIO
                    if [ "$ORARIO_INIZIO_NUM" -lt "$DATA_INIZIO_LOG" ]; then
                         NUM_RIGA_INIZIO=1
                         echo  "$(time_stamp) --> Data inizio non nel log. Num riga:1"
                    elif [ "$ORARIO_INIZIO_NUM" -gt "$DATA_FINE_LOG" ]; then
                         NUM_RIGA_INIZIO=$RIGHE_LOG
                         echo  "$(time_stamp) --> Data inizio non nel log. Num riga:$NUM_RIGA_INIZIO"
                    else
                          check_orario_inizio
                    fi

                    ORARIO_INIZIO=$ORARIO_INIZIO_INPUT

                    echo  "$(time_stamp) --> Check Orario fine $ORARIO_FINE"
                    ORARIO_FINE_NUM=$(native2range $ORARIO_FINE)
                    ORARIO_FINE_NUM=$ORARIO_FINE_NUM"00"
                    native2montini $ORARIO_FINE_INPUT
                    GIORNO=$(expr $GIORNO + 1 - 1 )
                    if [ $GIORNO -le 9 ]; then
                      ORARIO_FINE="$MESE  $GIORNO $ORA"
                    else
                      ORARIO_FINE="$MESE $GIORNO $ORA"
                    fi
                    if [ "$ORARIO_FINE_NUM" -lt "$DATA_INIZIO_LOG" ]; then
                         NUM_RIGA_FINE=1
                         echo  "$(time_stamp) --> Data fine non nel log. Num riga:1"
                    elif [ "$ORARIO_FINE_NUM" -gt "$DATA_FINE_LOG" ]; then
                         NUM_RIGA_FINE=$RIGHE_LOG
                         echo  "$(time_stamp) --> Data fine non nel log. Num riga:$NUM_RIGA_FINE"
                    else
                        check_orario_fine
                    fi
                    echo  "$(time_stamp) --> Creazione file di output $FILE_OUT"
                    estrae_log
                done


            ;;
            -n)
                # Estrazione nconn
                MINARG=3
                check_argv
                ORARIO_INIZIO_INPUT=$2
                ORARIO_FINE_INPUT=$3
                echo "$(time_stamp) --> Inizio Esecuzione Comando: $0 $1 \"$2\" \"$3\" "
                # Controllo formale dati di input
                check_orario $ORARIO_INIZIO_INPUT
                check_orario $ORARIO_FINE_INPUT
                PLATFORM=$(uname)
                echo  "$(time_stamp) --> Estrazione nconn"
                nconn
                echo "$(time_stamp) --> Fine Esecuzione Comando"
            ;;
            -D)
                # Formato data: 2011/07/06 03:31:42:063
                # Estrazione SDP.log
                MINARG=3
                check_argv
                ORARIO_INIZIO_INPUT=$2
                ORARIO_FINE_INPUT=$3
                echo "$(time_stamp) --> Inizio Esecuzione Comando: $0 $1 \"$2\" \"$3\" "
                # Controllo formale dati di input
                check_orario $ORARIO_INIZIO_INPUT
                check_orario $ORARIO_FINE_INPUT
                #ORARIO_INIZIO=$(trasforma_orario_SDP $ORARIO_INIZIO_INPUT)
                #ORARIO_FINE=$(trasforma_orario_SDP $ORARIO_FINE_INPUT)
                # Copia orario input per i file successivi
                #ORARIO_INIZIO_INPUT=$ORARIO_INIZIO
                #ORARIO_FINE_INPUT=$ORARIO_FINE
                echo  "$(time_stamp) --> Estrazione SDP.log"
                DIR_LOG=$DIR_SDP_LOG
                lista_log_SDP "SDP.lo*"
                TIME_FORMAT="SDP"
                for FILE_LOG in $LISTA_LOG
                do
                    # Calcolo righe log
                    RIGHE_LOG=$(wc -l $FILE_LOG | awk '{ print $1 }')
                    # Partenza con i dati di input
                    ORARIO_INIZIO=$ORARIO_INIZIO_INPUT
                    ORARIO_FINE=$ORARIO_FINE_INPUT
                    FILE_OUT=$(echo $FILE_LOG | awk -F/ '{ print $6 "."  $7 }')
                    FILE_OUT=$HOSTNAME.$FILE_OUT
                    # Calcolo range del file di log
                    range_log_SDP
                    #echo "Inizio Log $DATA_INIZIO_LOG fine log $DATA_FINE_LOG"
                    echo  "$(time_stamp) --> Estrazione file $FILE_OUT"
                    echo  "$(time_stamp) --> Check Orario inizio $ORARIO_INIZIO"
                    ORARIO_INIZIO_NUM=$(native2range $ORARIO_INIZIO)
                    ORARIO_INIZIO_NUM=$ORARIO_INIZIO_NUM"00"
                    #echo "inizio estr $ORARIO_INIZIO_NUM"
                    #echo $ORARIO_INIZIO_INPUT
                    ORARIO_INIZIO=$(trasforma_orario_SDP $ORARIO_INIZIO_INPUT)
                    
                    ORARIO_FINE_NUM=$(native2range $ORARIO_FINE)
                    ORARIO_FINE_NUM=$ORARIO_FINE_NUM"59"
                    ORARIO_FINE=$(trasforma_orario_SDP $ORARIO_FINE_INPUT)
                    #echo "fine estr $ORARIO_FINE_NUM"
                    #echo $ORARIO_INIZIO
                    #echo  $ORARIO_INIZIO_NUM  $DATA_INIZIO_LOG
                    if [ $ORARIO_INIZIO_NUM -lt $DATA_INIZIO_LOG ]; then
                         NUM_RIGA_INIZIO=1
                         echo  "$(time_stamp) --> Data inizio non nel log. Num riga:1"
                    elif [ $ORARIO_INIZIO_NUM -gt $DATA_FINE_LOG ]; then
                         NUM_RIGA_INIZIO=$RIGHE_LOG
                         echo  "$(time_stamp) --> Data inizio non nel log. Num riga:$NUM_RIGA_INIZIO"
                    else
                          check_orario_inizio
                    fi
                    echo  "$(time_stamp) --> Check Orario fine $ORARIO_FINE_INPUT"

                    # Serve per non bypassare il range
                    ORARIO_INIZIO=$(trasforma_orario_SDP $ORARIO_INIZIO_INPUT )
                    #echo "Inizio Log $DATA_INIZIO_LOG fine log $DATA_FINE_LOG"
                    #echo "inizio estr $ORARIO_INIZIO_NUM"
                    #echo "fine estr $ORARIO_FINE_NUM"
                    if [ $ORARIO_FINE_NUM -lt $DATA_INIZIO_LOG ]; then
                         NUM_RIGA_FINE=1
                         echo  "$(time_stamp) --> Data fine non nel log. Num riga:1"
                    elif [ $ORARIO_FINE_NUM -gt $DATA_FINE_LOG ]; then
                         NUM_RIGA_FINE=$RIGHE_LOG
                         echo  "$(time_stamp) --> Data fine non nel log. Num riga:$NUM_RIGA_FINE"
                    else
                        check_orario_fine
                    fi
                    echo  "$(time_stamp) --> Creazione file .gz"
                    estrae_log_compress
                done
                #echo  "$(time_stamp) --> Cancellazione file vuoti"
                #clean_empty
                #echo  "$(time_stamp) --> Creazione file .gz"
                #create_compress *SDP*
                echo "$(time_stamp) --> Fine Esecuzione Comando"
            ;;
            -h | *)
                show_help
esac