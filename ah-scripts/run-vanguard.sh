#!/bin/bash

set -ex

REVISION=$1

TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%S.%3NZ")

version_id=$(ah create-version-via-url --name "@ga-${TIMESTAMP}-${REVISION:0:7}" --input-type git --url https://github.com/Veridise/simple-marketplace.git --revision $REVISION)
task_id=$(ah start-defi-vanguard-task --version-id ${version_id} --detector unchecked-return use-before-def)
ah monitor-task --task-id $task_id

task_info_json=$(ah get-task-info --task-id $task_id | grep -v "^+")
for sarif_id in `echo "$task_info_json" | jq -r '.artifacts[] | select(.name == "sarif.json") | .id'`
do
    ah get-task-artifact --task-id $task_id --artifact-id $sarif_id --output-file "./"$sarif_id".sarif" --log-level ERROR
    detector_name=$(jq -r '.runs[0].tool.driver.rules[0].id' "./"$sarif_id".sarif")
    mv "./"$sarif_id".sarif" "./"$detector_name".sarif"
done