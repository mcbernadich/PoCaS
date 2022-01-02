#!/bin/bash
#This script just calls all the other ones that create the ULX samples and subsamples. It must come with an argument to work. Said arguments can be: XMM or eRASS
path=$1
if [ "$path" = "XMM" ]; then
  echo "|----------------------------------------------------------------------------------|"
  echo "|                                                                                  |"
  echo "|We are going down the XMM-Newton rabbit hole. Be prepared for an ULX flood.       |"
  echo "|                                                                                  |"
  echo "|----------------------------------------------------------------------------------|"
  echo "|                                                                                  |"
  echo "|We start with the XMM-HECATE correlation + contaminant pipeline.                  |"
  echo "|                                                                                  |"
  echo "|----------------------------------------------------------------------------------|"
  bash ULX_XMM_HECATE.sh
  echo "|----------------------------------------------------------------------------------|"
  echo "|                                                                                  |"
  echo "|Done. Now we look for ULX candidadates of quality.                                |"
  echo "|                                                                                  |"
  echo "|----------------------------------------------------------------------------------|"
  bash SourceDivisionXMM.sh
  echo "|----------------------------------------------------------------------------------|"
  echo "|                                                                                  |"
  echo "|Beautifully done. Now we build the complete subsamples quality.                   |"
  echo "|                                                                                  |"
  echo "|----------------------------------------------------------------------------------|"
  bash complete_XMM.sh
  echo "|----------------------------------------------------------------------------------|"
  echo "|                                                                                  |"
  echo "|You have grown to be the mighty warrior of the seven great ULXs. My job is done.  |"
  echo "|                                                                                  |"
  echo "|----------------------------------------------------------------------------------|"
elif [ "$path" = "eRASS" ]; then
  echo "|----------------------------------------------------------------------------------|"
  echo "|                                                                                  |"
  echo "|We are going down the eROSITA rabbit hole. Be prepared for an ULX flood.          |"
  echo "|                                                                                  |"
  echo "|----------------------------------------------------------------------------------|"
  echo "|                                                                                  |"
  echo "|Well, we would if it was ready. Try again after summer vacations.                 |"
  echo "|                                                                                  |"
  echo "|----------------------------------------------------------------------------------|"
else
  echo "If I were you, I would write either 'XMM' or 'eRASS' as an argument, even though the 'eRASS' track is not complete yet."
fi
echo "Done?"

