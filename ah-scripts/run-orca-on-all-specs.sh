#!/bin/bash

REVISION=$1
SPECS=${@:2}

EXIT_CODE=0

TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%S.%3NZ")
VERSION_ID=$(ah create-version-via-url --name "@ga-${TIMESTAMP}-${REVISION:0:7}" --input-type git --url https://github.com/Veridise/simple-marketplace.git --revision $REVISION)

for SPEC in ${SPECS}
do
  ./ah-scripts/run-orca-with-spec.sh ${REVISION} ${VERSION_ID} ${SPEC}

  if (($? != 0)); then
    echo "OrCa found counterexample for spec: ${SPEC}"
    EXIT_CODE=1
  fi
done

exit ${EXIT_CODE}