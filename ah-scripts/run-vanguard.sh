#!/bin/bash

set -e

REVISION=$1

TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%S.%3NZ")

version_id=$(ah create-version-via-url --name "@ga-${TIMESTAMP}-${REVISION:0:7}" --input-type git --url https://github.com/Veridise/simple-marketplace.git --revision $REVISION)
task_id=$(ah start-defi-vanguard-task --version-id ${version_id} --detector unchecked-return use-before-def)
ah monitor-task --task-id $task_id 

task_info_json=$(ah get-task-info --task-id $task_id | grep -v "^+")

mapfile -t detector_steps < <(echo "$task_info_json" | jq -r '.steps[] | select(.definition.is_tool) | .code')

for detector_step in "${detector_steps[@]}"; do
    # remove any funny characters from the step code to make sure we can preserve a file in the current directory
    sarif_file_name="./${detector_step//[^A-Za-z0-9._-]/_}.sarif"
    ah download-artifact --task-id $task_id --step-code "$detector_step" --name sarif.json --output-file "$sarif_file_name" --log-level ERROR
    detector_name=$(jq -r '.runs[0].tool.driver.rules[0].id' "$sarif_file_name")
    mv "$sarif_file_name" "./$detector_name.sarif"
done