#!/bin/bash

# CMP_SC 1050 Submission Backup Script
# Written by Matt Marlow and Daphne Zou
# 1/23/2023

set -e

# Check if lab number is present
if [[ -z $1 ]]; then
    echo "********************************************************"
    echo "*    Syntax: ./backup.sh lab[*]              "
    echo "*    where [*] is the lab number (1~13)      "
    echo "********************************************************"
    exit 1
fi
# ----------------------------------

# Check if source folder exists
source_dir="/group/cs1050/submissions/1050/A/$1/.valid"
if test ! -d "$source_dir"; then
    echo "********************************************************"
    echo "*    Error: $1 submissions not available            "
    echo "*    Please wait until the lab session takes place "
    echo "********************************************************" 
    exit 1
fi
# ----------------------------------

# Folder creation
echo "Executing backup script"
file="${PWD}/pawprints.txt"
if test ! -f "$file"; then 
    echo "********************************************************"
    echo "*    No pawprints.txt file detected.           "
    echo "*    Please run script gen-group-roster        "
    echo "*    to create a .txt file containing the      "
    echo "*    pawprints you wish to grade/backup.       "
    echo "********************************************************" 
    exit 1
fi
new_directory="cs1050_local_labs"
if test ! -d "$new_directory"; then
    echo "No local folder detected. Creating folder"
    mkdir "$new_directory"
fi
cd "${PWD}"/$new_directory || exit
new_directory=$1_backup
if test ! -d "$new_directory"; then
    echo "Creating $1 folder for backup"
    mkdir "$1"_backup
else
    echo "A backup already exists. Clearing old one and making new one!"
    rm -rf "$1"_backup
fi 
# ----------------------------------

echo "-----------------------------------"

# Copy student submissions
missing="missing_submissions.txt"
while read p || [[ -n $p ]]; do 
    if ! cp -rL /group/cs1050/submissions/1050/A/"$1"/"$p" "$1"_backup 2> /dev/null ; then
        echo "$p" >> $missing # If no valid submission, add them to the (temporary) invalid list so we can go look for them (maybe they submitted late?)
        echo "$p DID NOT SUBMIT A COMPILING LAB WITHIN WINDOW"
    fi    
done < "$file"
# ----------------------------------

echo "-----------------------------------"

# Search for invalid entries 
if test -f "$missing"; then
    while read p || [[ -n $p ]]; do 
    if ! cp -rL /group/cs1050/submissions/1050/A/"$1"/.invalid/*"$p"* "$1"_backup 2> /dev/null ; then
        echo "$p SUBMISSION IS COMPLETELY MISSING. AUTOMATIC 0"
    fi    
done < "$missing"
fi
# ----------------------------------

# Delete missing submissions file (temp)
if test -f "$missing"; then
    rm "$missing"
fi
# ----------------------------------
