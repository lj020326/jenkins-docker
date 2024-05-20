#!/bin/sh

########################
## EXPANDING VARIABLES FROM DOCKER SECRETS
## REFERENCES:
##   https://github.com/rbdiang/docker-secrets-example
##   https://gist.github.com/bvis/b78c1e0841cfd2437f03e20c1ee059fe
##   https://github.com/DevilaN/docker-entrypoint-example
##   https://stackoverflow.com/questions/48094850/docker-stack-setting-environment-variable-from-secrets
## source: https://gist.github.com/soloman1124/cdcf8e603f3064b2b49d614c6ed45a92

set -e

echo "$0: Looking for shell scripts in /docker-entrypoint.d/"
#. /docker-entrypoint.d/env_secrets_expand.sh
. /docker-entrypoint.d/.env-from-docker-secrets

if /usr/bin/find "/docker-entrypoint.d/" -mindepth 1 -maxdepth 1 -type f -print -quit 2>/dev/null | read v; then
    echo "$0: /docker-entrypoint.d/ is not empty, will attempt to perform configuration"

    echo "$0: Looking for shell scripts in /docker-entrypoint.d/"
    find "/docker-entrypoint.d/" -follow -type f -print | sort -V | while read -r f; do
    case "$f" in
        *.sh)
            if [ -x "$f" ]; then
                echo "$0: Launching $f";
                "$f"
            else
                # warn on shell scripts without exec bit
                echo "$0: Ignoring $f, not executable";
            fi
            ;;
        *) echo "$0: Ignoring $f";;
    esac
done

echo "$0: Configuration complete; ready for start up"
else
    echo "$0: No files found in /docker-entrypoint.d/, skipping configuration"
fi

exec "$@"
