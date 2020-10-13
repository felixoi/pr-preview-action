#!/bin/sh -l

if [ -z "$GITHUB_TOKEN" ]
then
      echo "\$GITHUB_TOKEN is empty"
else
      echo "\$GITHUB_TOKEN is NOT empty"
fi

if [ -z "$PA_TOKEN" ]
then
      echo "\$PA_TOKEN is empty"
else
      echo "\$PA_TOKEN is NOT empty"
fi

if [ -z "$REPOSITORY" ]
then
      echo "\$REPOSITORY is empty"
else
      echo "\$REPOSITORY is NOT empty"
fi

exit 0
