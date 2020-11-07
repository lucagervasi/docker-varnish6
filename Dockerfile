FROM centos:centos7 as builder

ENV VARNISH=6.0.7-1.el7
ENV VARNISH_MODULES=6.0-lts

ADD varnishcache6.repo /etc/yum.repos.d/varnishcache6.repo
RUN yum -y install epel-release && \
    yum install -y varnish-${VARNISH} varnish-devel git python-docutils && \
    yum groupinstall -y "Development tools"


RUN mkdir /git && cd /git && git clone -b ${VARNISH_MODULES} https://github.com/varnish/varnish-modules.git && \
  cd /git/varnish-modules && \
  ./bootstrap && \
  ./configure && \
  make && \
  make install


FROM centos:centos7
ENV VARNISH=6.0.7-1.el7
ENV VARNISH_MODULES=6.0-lts

MAINTAINER Luca Gervasi <varnish6@ashetic.net>

ADD varnishcache6.repo /etc/yum.repos.d/varnishcache6.repo
ADD start.sh /start.sh

# Needed to satisfy jemalloc library
RUN yum -y install epel-release && \
    yum install -y varnish-${VARNISH} && \
    yum clean all && \
    rm -rf /var/cache/yum && \
    chmod 755 /start.sh

COPY --from=builder /usr/lib64/varnish/vmods /usr/lib64/varnish/vmods

ENV VCL_CONFIG      /etc/varnish/default.vcl
ENV CACHE_SIZE      64m
ENV VARNISHD_PARAMS -p thread_pool_min=5 -p thread_pool_max=500 -p thread_pool_timeout=300 -p feature=+esi_disable_xml_check -p feature=+esi_ignore_other_elements -p feature=+esi_remove_bom -p feature=+http2  -p pcre_match_limit_recursion=64 -p syslog_cli_traffic=off -p sigsegv_handler=on -p workspace_client=2m -p workspace_backend=2m -p http_max_hdr=128 -p http_req_hdr_len=16K -p http_resp_hdr_len=16k -p http_req_size=2m -p http_resp_size=2m -p thread_pool_stack=256k
CMD /start.sh
EXPOSE 80
EXPOSE 6086
