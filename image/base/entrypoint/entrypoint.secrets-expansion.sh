#!/usr/bin/env sh

## source: https://gist.github.com/soloman1124/cdcf8e603f3064b2b49d614c6ed45a92

: ${ENV_SECRET_DIR:=/run/secrets}

beginswith() { case $2 in "$1"*) true;; *) false;; esac; }

dksec_expand() {
  for env_var in $(printenv)
  do
    value=$(echo $env_var | cut -d"=" -f2)
    if beginswith "dksec://" $value;
    then
      key=$(echo $env_var | cut -d"=" -f1)
      value=${value#"dksec://"}
      value=$(cat $ENV_SECRET_DIR/$value)
      export "$key"="$value"
    fi
  done
}

dksec_expand

exec "$@"