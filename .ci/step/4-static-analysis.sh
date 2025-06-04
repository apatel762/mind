#!/usr/bin/env bash

log_info "not implemented"

#(
#    set -x
#    "${PROJECT_ROOT}/mvnw" "${MVN_ARGS[@]}" -Dsonar.host.url=$SONAR_URL -Dsonar.login=$SONAR_TOKEN -- sonar:sonar
#)
#
# BUGS=$(curl -s "$SONAR_URL/api/measures/component?component=$APP_NAME&metricKeys=bugs" -H "Authorization: Bearer $SONAR_TOKEN" | jq '.component.measures[0].value')
# VULNERABILITIES=$(curl -s "$SONAR_URL/api/measures/component?component=$APP_NAME&metricKeys=vulnerabilities" -H "Authorization: Bearer $SONAR_TOKEN" | jq '.component.measures[0].value')
#
# if (( $(echo "$BUGS > $MAXIMUM_ALLOWED_BUGS" | bc -l) )); then
#     log_error "Too many bugs found: $BUGS > $MAXIMUM_ALLOWED_BUGS"
#     exit 1
# fi
#
# if (( $(echo "$VULNERABILITIES > $MAXIMUM_ALLOWED_VULNERABILITIES" | bc -l) )); then
#     log_error "Too many vulnerabilities found: $VULNERABILITIES > $MAXIMUM_ALLOWED_VULNERABILITIES"
#     exit 1
# fi
