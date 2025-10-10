#!/bin/bash

REVISION=$1
VERSION_ID=$2
SPEC=$3

task_id=$(ah start-orca-task --version-id ${VERSION_ID} --timeout 60 --embedded-specs ${SPEC})
ah monitor-task --task-id $task_id
ah get-task-info --verify --output none
