ARG CONTAINER=immortalwrt/sdk
ARG ARCH=mips_24kc
FROM $CONTAINER:$ARCH

LABEL "com.github.actions.name"="OpenWrt SDK"

ADD entrypoint.sh /

USER root

ENTRYPOINT ["/entrypoint.sh"]
