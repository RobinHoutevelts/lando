#!/bin/bash

# Get the lando logger
. /helpers/log.sh

# Set the module
LANDO_MODULE="sqlimport"

# Set generic config
FILE=""
WIPE=true
HOST=localhost
SERVICE=$LANDO_SERVICE_NAME

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

# PARSE THE ARGZZ
while (( "$#" )); do
  case "$1" in
    -h|--host|--host=*)
      if [ "${1##--host=}" != "$1" ]; then
        shift
      else
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
    --no-wipe)
        WIPE=false
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
      if [[ "$1" = /* ]]; then
        FILE="${1//\\//}"
      else
        FILE="$(pwd)/${1//\\//}"
      fi
      shift
      ;;
  esac
done

# Set positional arguments in their proper place
eval set -- "$FILE"
PV=""
CMD=""

# Use file or stdin
if [ ! -z "$FILE" ]; then
  # Validate we have a file
  if [ ! -f "$FILE" ]; then
    lando_red "File $FILE not found!"
    exit 1;
  fi

  CMD="$FILE"
else
  # Build DB specific connection string
  if [[ ${POSTGRES_DB} != '' ]]; then
    CMD="psql postgresql://$USER@$HOST:$PORT/$DATABASE"
  else
    CMD="mysql -h $HOST -P $PORT -u $USER ${LANDO_EXTRA_DB_IMPORT_ARGS}"
  fi

  # Read stdin into DB
  $CMD #>/dev/null
  exit 0;
fi

# Inform the user of things
echo "Preparing to import $FILE into database '$DATABASE' on service '$SERVICE' as user $USER..."

# Wipe the database if set
if [ "$WIPE" == "true" ]; then
  echo ""
  echo "Destroying all current tables in $DATABASE... "
  lando_yellow "NOTE: See the --no-wipe flag to avoid this step!"
  echo ""

  # DO db specific wiping
  if [[ ${POSTGRES_DB} != '' ]]; then
    # Drop and recreate database
    lando_yellow "\t\tDropping database ...\n\n"
    psql postgresql://$USER@$HOST:$PORT/postgres -c "drop database $DATABASE"

    lando_green "\t\tCreating database ...\n\n"
    psql postgresql://$USER@$HOST:$PORT/postgres -c "create database $DATABASE"
  else
    # Build the SQL prefix
    SQLSTART="mysql -h $HOST -P $PORT -u $USER ${LANDO_EXTRA_DB_IMPORT_ARGS} $DATABASE"

    # Gather and destroy tables
    TABLES=$($SQLSTART -e 'SHOW TABLES' | awk '{ print $1}' | grep -v '^Tables' )

    # PURGE IT ALL! BURN IT TO THE GROUND!!!
    for t in $TABLES; do
      echo "Dropping $t table from $DATABASE database..."
      $SQLSTART -e "DROP TABLE $t"
    done
  fi
fi

# Check to see if we have any unzipping options or GUI needs
if command -v gunzip >/dev/null 2>&1 && gunzip -t $FILE >/dev/null 2>&1; then
  echo "Gzipped file detected!"
  if command -v pv >/dev/null 2>&1; then
    CMD="pv $CMD"
  else
    CMD="cat $CMD"
  fi
  CMD="$CMD | gunzip"
elif command -v unzip >/dev/null 2>&1 && unzip -t $FILE >/dev/null 2>&1; then
  echo "Zipped file detected!"
  CMD="unzip -p $CMD"
  if command -v pv >/dev/null 2>&1; then
    CMD="$CMD | pv"
  fi
else
  if command -v pv >/dev/null 2>&1; then
    CMD="pv $CMD"
  else
    CMD="cat $CMD"
  fi
fi

# Build DB specific import command
if [[ ${POSTGRES_DB} != '' ]]; then
  CMD="$CMD | psql postgresql://$USER@$HOST:$PORT/$DATABASE"
else
  CMD="$CMD | mysql -h $HOST -P $PORT -u $USER ${LANDO_EXTRA_DB_IMPORT_ARGS} $DATABASE"
fi

# Import
lando_pink "Importing $FILE..."
if command eval "$CMD"; then
  STATUS=$?
else
  STATUS=1
fi

# Finish up!
if [ $STATUS -eq 0 ]; then
  lando_green "Import complete!"
else
  lando_red "Import failed."
  exit $STATUS
fi
