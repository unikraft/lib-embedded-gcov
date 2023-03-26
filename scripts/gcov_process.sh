#!/bin/bash
set -e

# -b is used for binary dump and -c is used for console log
if [[ $# -ne 3 ]]; then
	echo "Usage: $0 [-b <binary_dump> | -c <console_text>] <build_dir>"
	exit
fi

if [ -n "${CROSS_COMPILE}" ]; then
	GCOV=${CROSS_COMPILE}/gcov
else
	GCOV=$(which gcov)
fi

if [ -z "$GCOV" ]; then
	echo "$0: Could not find gcov"
	exit
fi

SCRIPT_DIR=$(realpath $(dirname $0))
PARSE_SCRIPT=${SCRIPT_DIR}/gcov_binary_file_parse.py
BUILD_DIR=$(realpath $3)
OUTPUT_FILE=$(realpath $2)
GCOV_DIR=${BUILD_DIR}/libembeddedgcov/origin

cd ${GCOV_DIR}/scripts

rm -rf ../objs/*
rm -rf ../results/*

find $BUILD_DIR -type d -name objs -prune -o -name \*.gcno -exec cp {} ../objs/ \;

lcov --gcov-tool ${CROSS_COMPILE}gcov --capture --initial \
     --directory ../objs/ -o ../results/baseline.info

if [[ $1 == "-b" ]]; then
	python3 ${PARSE_SCRIPT} --filename ${OUTPUT_FILE} --output ../objs/
elif [[ $1 == "-c" ]]; then
	./gcov_convert.sh $OUTPUT_FILE
fi

echo

./lcov_newcoverage.sh
./lcov_combine_new_base.sh
./genhtml_report.sh

echo -e "\nlcov report in file://$(realpath ../results/html)/index.html\n"
