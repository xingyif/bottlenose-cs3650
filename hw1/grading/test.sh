#!/bin/bash
OUTPUT=$(cat strings.rkt | racket | grep "\"hello world\"")

echo "1..1"

if [ "$OUTPUT" != '' ]; then
    echo "ok 1 - strings.rkt"
else
    echo "not ok 2 - strings.rkt"
fi
