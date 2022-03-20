FROM ubuntu:18.04

LABEL maintainer "S. Evan Staton"
LABEL image_type "HMMER2GO: Annotate DNA sequences for Gene Ontology terms"

ARG latest_tag
ENV latest_tag=$latest_tag

RUN apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y -qq \
    emboss zlib1g-dev libxml2-dev libexpat1-dev libssl-dev libdb-dev hmmer cpanminus git \
    && rm -rf /var/lib/apt/lists/* \
    && echo "n" | cpanm -q -n Bio::DB::Taxonomy::entrez \
    && cpanm https://github.com/sestaton/HMMER2GO/archive/refs/tags/${latest_tag}.tar.gz \
    && apt-get remove -y git cpanminus
