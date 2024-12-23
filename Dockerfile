FROM python:alpine as base
ENV PIP_NO_CACHE_DIR=1
COPY install-s6.sh /tmp/install-s6.sh
RUN mkdir -p /var/www \
    && apk add --no-cache bash curl gawk unit wget \
    && chown -R unit:unit /var/www \
    && ln -sf /dev/stdout /var/log/unit.log \
    && ln -sf /dev/stdout /var/log/access.log \
    && /tmp/install-s6.sh

FROM base
ADD https://github.com/sycured/xml2json/raw/master/xml2json.py /opt/xml2json.py
COPY service_crond /etc/s6-overlay/s6-rc.d/cron/run
COPY service_unitd /etc/s6-overlay/s6-rc.d/nginx/run
RUN chmod +x /opt/xml2json.py \
    && pip install defusedxml \
    && echo "longrun" > /etc/s6-overlay/s6-rc.d/cron/type \
    && echo "longrun" > /etc/s6-overlay/s6-rc.d/nginx/type \
    && echo "de" > /etc/s6-overlay/s6-rc.d/nginx/dependencies \
    && mkdir /etc/s6-overlay/s6-rc.d/de \
    && echo "oneshot" > /etc/s6-overlay/s6-rc.d/de/type \
    && echo "exec bash -c '/usr/local/bin/docker-entrypoint.sh'" > /etc/s6-overlay/s6-rc.d/de/up \
    && touch /etc/s6-overlay/s6-rc.d/user/contents.d/nginx \
    && touch /etc/s6-overlay/s6-rc.d/user/contents.d/cron

COPY config.json /docker-entrypoint.d/
COPY dl_and_convert /etc/periodic/15min/
COPY dl_at_boot.sh set_access_log.sh /docker-entrypoint.d/
COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh

ENV S6_SERVICES_GRACETIME=300000
ENV S6_CMD_WAIT_FOR_SERVICES_MAXTIME=5000000

EXPOSE 8000
ENTRYPOINT ["/init"]