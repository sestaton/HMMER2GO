FROM ubuntu:18.04

LABEL maintainer "S. Evan Staton"
LABEL image_type "HMMER2GO: Annotate DNA sequences for Gene Ontology terms"

RUN apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y -qq \
    emboss zlib1g-dev libxml2-dev libexpat1-dev libssl-dev hmmer cpanminus git \
    && rm -rf /var/lib/apt/lists/* \
    && cpanm git://github.com/sestaton/HMMER2GO.git \
    && apt-get remove -y git cpanminus
