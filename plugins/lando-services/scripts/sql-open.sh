#!/bin/bash

printenv;

if ! [ -x "$(command -v jq)" ]; then
  echo "jq not found please run:"
  echo "docker exec -it ${HOSTNAME} /bin/bash -c 'apt-get update -y && apt-get install jq -y'"
  exit 1
  apt-get update -y
  apt-get install jq -y
fi

jq --version

exit;

# Set generic things
HOST=localhost
STDOUT=false

# colors
GREEN='\033[0;32m'
RED='\033[31m'
DEFAULT_COLOR='\033[0;0m'

# Get type-specific config
if [[ ${POSTGRES_DB} != '' ]]; then
  DATABASE=${POSTGRES_DB:-database}
  PORT=5432
  USER=postgres
else
  DATABASE=${MYSQL_DATABASE:-database}
  PORT=3306
  USER=root
fi

# Set the default filename
FILE=${DATABASE}.`date +"%Y-%m-%d-%s"`.sql

# PARSE THE ARGZZ
# TODO: compress the mostly duplicate code below?
while (( "$#" )); do
  case "$1" in
    -h|--host|--host=*)
      if [ "${1##--host=}" != "$1" ]; then
        HOST="${1#*=}"
        shift
      else
        HOST="$2"
        shift 2
      fi
      ;;
    -db|--database|--database=*)
      if [ "${1##--database=}" != "$1" ]; then
        DATABASE="${1#*=}"
        shift
      else
        DATABASE="$2"
        shift 2
      fi
      ;;
    --stdout)
        STDOUT=true
        shift
      ;;
    --)
      shift
      break
      ;;
    -*|--*=)
      shift
      ;;
    *)
      FILE="$(pwd)/$1"
      shift
      ;;
  esac
done

if [[ ${POSTGRES_DB} != '' ]]; then
  echo -e "postgresql://$USER@localhost:$PORT/$DATABASE"
  exit
else
  echo -e "mysql://${USER}:${USER}@${HOST}:${PORT}/${DATABASE}"
fi

echo ''
