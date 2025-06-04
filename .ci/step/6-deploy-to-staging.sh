#!/usr/bin/env bash

log_info "not implemented"

# DEPLOY_PACKAGE="$APP_NAME-$APP_VERSION-$CURRENT_GIT_COMMIT.tar.gz"
# tar -czf $DEPLOY_PACKAGE -C artifacts .
#
# scp $DEPLOY_PACKAGE $DEPLOY_USER@$STAGING_SERVER:/tmp/
#
# ssh $DEPLOY_USER@$STAGING_SERVER << EOF
#     mkdir -p /opt/$APP_NAME
#     tar -xzf /tmp/$DEPLOY_PACKAGE -C /opt/$APP_NAME
#     systemctl restart $APP_NAME
#     rm /tmp/$DEPLOY_PACKAGE
# EOF
#
# HEALTH_CHECK=$(curl -s -o /dev/null -w "%{http_code}" http://$STAGING_SERVER:8080/health)
# if [ "$HEALTH_CHECK" != "200" ]; then
#     log_error "Deployment health check failed with status: $HEALTH_CHECK"
#     exit 1
# fi
