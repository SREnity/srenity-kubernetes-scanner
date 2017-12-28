FROM google/cloud-sdk:alpine

MAINTAINER Robert Warmack <robert@srenity.io>

ENV PUBLIC_ID "XXXX"
ENV PRIVATE_KEY "XXXX"

RUN apk --no-cache add coreutils jq openssl
RUN apk --update add openjdk7-jre
RUN gcloud components install kubectl

ADD entrypoint.sh .

CMD ["./entrypoint.sh"]
