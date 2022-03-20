#!/bin/bash

set -euo pipefail

vers=$(egrep "our.*VERSION" bin/hmmer2go | sed "s/^.* '//;s/'.*$//")
latest_tag=$(git describe --tags `git rev-list --tags --max-count=1`)
echo -e "\n=====> Building Docker image for HMMER2GO v$vers\n"

#--build-arg LC_ALL=C
# build
docker build \
  --build-arg latest_tag=$latest_tag \
  -t sestaton/hmmer2go:$vers .

# tag
docker tag sestaton/hmmer2go:$vers sestaton/hmmer2go:latest

# push
docker push sestaton/hmmer2go:$vers
docker push sestaton/hmmer2go:latest
