FROM       docker.xlands-inc.com/baoyu/php-fpm
MAINTAINER djluo <dj.luo@baoyugame.com>

ENV SOURCE http://sourceforge.net/projects/zentao/files/6.4/ZenTaoPMS.6.4.stable.zip/download

RUN export http_proxy="http://172.17.42.1:8080/" \
    && export DEBIAN_FRONTEND=noninteractive     \
    && apt-get update \
    && apt-get install -y wget unzip \
    && wget -O /zentao.zip $SOURCE   \
    && unzip /zentao.zip \
    && apt-get clean \
    && unset http_proxy DEBIAN_FRONTEND \
    && rm -rf usr/share/locale \
    && rm -rf usr/share/man    \
    && rm -rf usr/share/doc    \
    && rm -rf usr/share/info

ADD ./conf/php-fpm.conf  /etc/php5/fpm/php-fpm.conf
ADD ./entrypoint.pl /entrypoint.pl

ENTRYPOINT ["/entrypoint.pl"]
CMD        ["/usr/sbin/php5-fpm", "--fpm-config", "/etc/php5/fpm/php-fpm.conf"]
