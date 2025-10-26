#! /bin/bash
  set -e

  DIR_PATH=""

  echo "$(date): Starting kvideo run" 
  cd $DIR_PATH

  if docker-compose up  2>&1; then
    echo "$(date): Completed successfully" 
  else
    echo "$(date): Failed with exit code $?" 
    exit 1
  fi

