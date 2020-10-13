#!/bin/sh -l

if [ -z "$1" ]
then
      echo "\$GITHUB_TOKEN is empty"
else
      echo "\$GITHUB_TOKEN is NOT empty"
fi

if [ -z "$2" ]
then
      echo "\$PA_TOKEN is empty"
else
      echo "\$PA_TOKEN is NOT empty"
fi

if [ -z "$3" ]
then
      echo "\$REPOSITORY is empty"
else
      echo "\$REPOSITORY is NOT empty: $3"
fi

exit 0
