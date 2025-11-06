# Container image that runs your code
# Using Ubuntu 24.04 which has glibc 2.38+ (required by prequel CLI binary)
FROM ubuntu:24.04

RUN apt update && apt install -y curl sudo wget

COPY entrypoint.sh /entrypoint.sh

RUN chmod 777 entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]