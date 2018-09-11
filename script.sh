#!/bin/bash

# App variables.
#PROJECT_ID='6'
#SUITE_ID='5235'

PROJECT_ID='18'
SUITE_ID='4401'

# API variables.
TR_CREDS="${TR_USERNAME}:${TR_PASSWORD}"
BASE_URL='https://intouch.testrail.com/index.php?/api/v2'
CONTENT_TYPE='Content-Type: application/json'

# Check that creds have been sourced from the environment.
if [ $TR_CREDS == ":" ]; then
  echo "Add credentials to your ~/.bashrc file."
# export TR_USERNAME="iris@intouchhealth.com"
# export TR_PASSWORD="X2QdBu4MXpJcs9usi9iig07E"
  exit 1
fi

# Script paths.
SECTIONS_FILE=tr_sections.json
CASES_FILE=tr_cases.json


# Get all sections for the given suite.
echo 'Working...'

curl -s -H "$CONTENT_TYPE" -u "$TR_CREDS" \
     "$BASE_URL/get_sections/$PROJECT_ID&suite_id=$SUITE_ID" > $SECTIONS_FILE


# Get all test cases for the given suite.
curl -s -H "$CONTENT_TYPE" -u "$TR_CREDS" \
      "$BASE_URL/get_cases/$PROJECT_ID&suite_id=$SUITE_ID" > $CASES_FILE


ruby scriptruby.rb

# jq -r '(map(keys) | add | unique) as $cols | map(. as $row | $cols | map($row[.])) as $rows | $cols, $rows[] | @csv' result.json > result.csv

echo 'Done!'

rm $SECTIONS_FILE
rm $CASES_FILE

