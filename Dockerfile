# syntax=docker/dockerfile:1.3-labs

FROM postgres:16

# RUN <<EOF
#     apt-get update -qq &&
#     apt-get upgrade -qq &&
#     apt-get install -qq -y --no-install-recommends postgresql-client
# EOF
#
CMD bash

