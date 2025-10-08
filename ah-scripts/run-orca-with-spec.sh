#!/bin/bash

set -e

REVISION=$1
VERSION_ID=$2
SPEC=$3

task_id=$(ah start-orca-task --version-id ${VERSION_ID} --timeout 60 --embedded-specs ${SPEC})
ah monitor-task --task-id $task_id

task_info_json=$(ah get-task-info --task-id $task_id | grep -v "^+")
orca_findings_id=$(echo "$task_info_json" | jq -r '.artifacts[] | select(.name == "orca/findings.json") | .id')
ah get-task-artifact --task-id $task_id --artifact-id $orca_findings_id --output-file ./orca_findings_id.json
ORCA_CEXES=$(jq '.findings.critical' ./orca_findings_id.json)

if ((${ORCA_CEXES} != 0)); then
    echo "OrCa found a counterexample for spec: ${SPEC}"
    exit 1
fi