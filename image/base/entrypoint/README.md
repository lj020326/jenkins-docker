# Variables by Secrets

Sample script that allows you to define as environment variables the name of the docker secret that contains the secret value.
It will be in charge of analyze all the environment variables searching for the placeholder to substitute the variable value
by the secret.

## Usage

You can define the next environment variables:

```bash
$ env | grep DB_
DB_HOST=my-db-host
DB_USER=my-db-user
DB_PASS=my-db-pass
```

And nothing would happen. None of the variables would be modified when starting the container.

But if you define variables with the defined placeholder it will expand the value with the referred secret.

### Example

Create Secret
```bash
echo "my-db-pass" | docker secret create secret-db-pass -
```

```bash
$ env | grep DB_
DB_HOST=my-db-host
DB_USER=my-db-user
DB_PASS=dksec://secret-db-pass
```

When starting the script will search for the placeholder `dksec://xxxx` on each
environment variable and will substitute the value by the content of the secret `xxxx`,
in this example it means to end up with:

```bash
DB_HOST=my-db-host
DB_USER=my-db-user
DB_PASS=my-db-pass
```

### How to use it

If you want to use this feature on any image just add the env_secrets_expand.sh
file in your container entrypoint script and invoke it with `source env_secrets_expand.sh`

### How to test this

Build a sample image with the required dependency and enter into it:

```bash
docker run --rm -v $PWD:/test -it alpine sh
```

Just emulate the creation of a secret and the example variables with the next commands:

```bash
mkdir -p /run/secrets/
echo "my-db-pass" > /run/secrets/secret-db-pass
export DB_HOST=my-db-host
export DB_USER=my-db-user
export DB_PASS=dksec://secret-db-pass
```

Execute the script:

```bash
ENV_SECRETS_DEBUG=true /test/env_secrets_expand.sh
```

## Docker stack docker-compose service example

This trivial example allows for passing secret to service

docker-compose.yml
```yaml
version: "3.3"
services:
  simple:
    image: simple
    environment:
      - GREET=DOCKER-SECRET->greeting
      - ENV_SECRETS_DEBUG=true
      - NAME=Lee
    secrets:
       - greeting
secrets:
   greeting:
     external: true 
```

entrypoint.sh:
```bash
#!/bin/sh

source /env_secrets_expand.sh

echo "Here is the secret greeting: for $NAME"
echo "${GREET}${NAME}"
while : ;
do
  sleep 2
done
```

Dockerfile:
```Dockerfile
FROM alpine

COPY env_secrets_expand.sh /env_secrets_expand.sh
COPY my.sh /entrypoint.sh
ENTRYPOINT "/entrypoint.sh"

```

Steps followed for this example
1. Initialize swarm cluster:  
  `docker swarm init`
1. Create secret greeting:  
  `echo "Hello, " | docker secret create greeting -`
1. Build image:  
  `docker build . -t simple`
1. Run stack service:  
  `docker stack deploy -c docker-compose.yml simple-stack`
1. View logs on running container:  
  `docker logs $(docker ps | grep simple | awk  '{print $1}')`

## Expected output:
Output:  
```
Here is the secret greeting: for Lee
Hello, Lee
```

## Credit:

Credit for this implementation comes from this [gist](https://gist.github.com/bvis/b78c1e0841cfd2437f03e20c1ee059fe#file-env_secrets_expand-sh)

## Reference

- https://github.com/rbdiang/docker-secrets-example
- https://gist.github.com/bvis/b78c1e0841cfd2437f03e20c1ee059fe?permalink_comment_id=2317693#gistcomment-2317693
- https://gist.github.com/bvis/b78c1e0841cfd2437f03e20c1ee059fe
- https://github.com/DevilaN/docker-entrypoint-example
- https://stackoverflow.com/questions/48094850/docker-stack-setting-environment-variable-from-secrets
