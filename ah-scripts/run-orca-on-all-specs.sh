#!/bin/bash

set -x

REVISION=$1
SPECS=${@:2}

EXIT_CODE=0

for SPEC in ${SPECS}
do
  ./ah-scripts/run-orca-with-spec.sh ${REVISION} ${SPEC}

  if (($? != 0)); then
    echo "OrCa found counterexample for spec: ${SPEC}"
    EXIT_CODE=1
  fi
done

exit ${EXIT_CODE}