# Dockerfile for jenkins/sfyt integration demonstration
# we will use syft to look for curl in the image 
# and kill the jenkins job if we find it
FROM alpine:latest

## good dockerfile pieces
# RUN apk add --no-cache vim
# USER 65534:65534

## bad dockerfile
RUN apk add --no-cache sudo curl

CMD /bin/sh
