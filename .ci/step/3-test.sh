#!/usr/bin/env bash

(
    set -x
    "${PROJECT_ROOT}/mvnw" "${MVN_ARGS[@]}" -- test
)
