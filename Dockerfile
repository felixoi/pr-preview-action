# Container image that runs your code
FROM alpine:latest

RUN apk add --no-cache git curl jq rsync python3 py3-requests

# Copies your code file from your action repository to the filesystem path `/` of the container
COPY entrypoint.sh /entrypoint.sh
COPY scripts/ /scripts

# Code file to execute when the docker container starts up (`entrypoint.sh`)
ENTRYPOINT ["/entrypoint.sh"]
