#!/bin/bash
#======================================================
#   gen-group-roster
#   Script to generate grading group roster for CS1050
#
#   Daphne Zou   01/24/2023
#
#======================================================



set -e

usage() {
    cat <<HERE
    
===========================================================
Usage: $0 COURSE_ID GROUP_NAME [OUTPUT_FILE]
Example:  ./gen-group-roster.sh 145507 Daphne
Generate a roster file for grading groups using course id and group name. 
File contains the pawprints of all students in given grading group and 
will be stored in current directory.

ARGUMENTS
 
  COURSE_ID         The ID of the Canvas course. This can be found in the URL of
                    the course on Canvas which is in the format
                    https://umsystem.instructure.com/courses/COURSE_ID.
                    For Spring 2023, the ID is 145507.
  GROUP_NAME        Name of grading group on Canvas. Usually the first name of 
                    the TA in charge of that group. Check the "Grading Groups" tab
                    in "People" section of the Canvas page for exact group names.
  OUTPUT_FILE       (Optional) Name of the output roster file. Will be named 
                    "pawprints.txt" by default.
============================================================
HERE
    exit "${1:-0}"
}


# Check syntax
if [[ $# -lt 2 ]]; then
    usage
    exit 1
fi

if [[ -z $3 ]]; then
    OUTPUT_FILE="pawprints.txt"
else
    OUTPUT_FILE="$3"
fi

if [[ -f "${OUTPUT_FILE}" ]]; then
    rm -f "${OUTPUT_FILE}"
fi
#-------------------------------------

CANVAS_API="https://umsystem.instructure.com/api/v1/"
TOKEN="16765~H4OgOAbmC2uapHCSN7pFbzummd9Inp1EYDs70XtnNtvHaVnGWkpM6WjfGSAV6ouK"

# Check if course_id exists
COURSE_URL="${CANVAS_API}/courses/$1"
status=$(curl -sS -I "${COURSE_URL}" 2> /dev/null | head -n 1 | cut -d' ' -f2)
if [[ ${status} -eq 404 ]]; then
    echo "***   Course $1 does not exist. Please check your course id. ***"
    exit 1
fi
#-------------------------------------

# Check if user is authorized to access course
COURSE_RESP=$(curl "${COURSE_URL}" -i -Ss -H "Authorization: Bearer ${TOKEN}")
if [[ ${COURSE_RESP} == *"unauthorized"* ]]; then
    echo "***   You are not authorized to access course $1.     ***"
    exit 1
fi
#-------------------------------------

# Retrieve group info from course
GROUP_URL="${CANVAS_API}courses/$1/groups?per_page=100"
RESP=$(curl "${GROUP_URL}" -Ss -H "Authorization: Bearer ${TOKEN}" )
group_id=-1
for row in $(echo "${RESP}" | jq -r '.[] | @base64'); do
    _jq() {
        echo "${row}" | base64 --decode | jq -r "${1}"
    }
    if [[ "$(_jq '.name')" == "$2" ]]; then
        group_id="$(_jq '.id')"
        members_count="$(_jq '.members_count')"
        break
    fi
done

# Check if group with the given name exists
if [[ $group_id -lt 0 ]]; then
    echo "*** Error: cannot find group named \"$2\". Please check the group name again."
    exit 1
else
    echo "*** There are currently ${members_count} members in group \"$2\". "
fi
 
# If group exists, get all pawprints in the group and save it to roster file
MEMBERS_URL="${CANVAS_API}/groups/${group_id}/users?per_page=${members_count}"
RESP=$(curl "${MEMBERS_URL}" -Ss -H "Authorization: Bearer ${TOKEN}" )

for row in $(echo "${RESP}" | jq -r '.[] | @base64'); do
    _jq() {
        echo "${row}" | base64 --decode | jq -r "${1}"
    }
    echo $(_jq '.login_id') >> "$OUTPUT_FILE"
done
#-------------------------------------
   
if [[ ! -f "$OUTPUT_FILE" ]]; then
    echo "*** Cannot create file \"${OUTPUT_FILE}\". Please check again."
else
    echo "*** Output file \"${OUTPUT_FILE}\" successfully generated. "
fi
