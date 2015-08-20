FROM       docker.xlands-inc.com/baoyu/php-fpm
MAINTAINER djluo <dj.luo@baoyugame.com>

RUN export http_proxy="http://172.17.42.1:8080/" \
    && export DEBIAN_FRONTEND=noninteractive     \
    && apt-get update \
    && apt-get install -y unzip \
    && ZIP="http://sourceforge.net/projects/zentao/files/6.4/ZenTaoPMS.6.4.stable.zip/download" \
    && curl -sLo  /download $ZIP \
    && unzip      /download   \
    && /bin/rm -f /download   \
    && apt-get purge -y unzip \
    && apt-get autoremove -y  \
    && apt-get clean \
    && unset http_proxy DEBIAN_FRONTEND \
    && rm -rf usr/share/locale \
    && rm -rf usr/share/man    \
    && rm -rf usr/share/doc    \
    && rm -rf usr/share/info   \
    && find var/lib/apt -type f -exec rm -f {} \;

ADD ./entrypoint.pl      /entrypoint.pl
ADD ./conf/php-fpm.conf  /etc/php5/fpm/php-fpm.conf

ENTRYPOINT ["/entrypoint.pl"]
CMD        ["/usr/sbin/php5-fpm", "--fpm-config", "/etc/php5/fpm/php-fpm.conf"]
