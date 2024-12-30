FROM centos:7
#
# You'll need to download bcl-convert-3.6.3-1.el7.x86_64.rpm from
# https://support.illumina.com/downloads/bcl-convert-downloads.html
# Yay clickwrap licenses !
#
# Building:
#
# docker build -t bcl-convert:latest -t bcl-convert:3.6.3 .
# sudo singularity build bcl-convert.sif docker-daemon://bcl-convert:latest
#
# Running:
#
# bcl-convert wants to be able to write to /var/logs/bcl-convert, so we bind a user writable directory for it
# mkdir logs
# singularity exec --bind logs:/var/log/bcl-convert bcl-convert.sif bcl-convert --help
# _or_
# singularity exec -wf bcl-convert.sif bcl-convert --help
#

RUN sed -i s/mirror.centos.org/vault.centos.org/g /etc/yum.repos.d/CentOS-*.repo
RUN sed -i s/^#.*baseurl=http/baseurl=http/g /etc/yum.repos.d/CentOS-*.repo
RUN sed -i s/^mirrorlist=http/#mirrorlist=http/g /etc/yum.repos.d/CentOS-*.repo

ADD bcl-convert-4.3.6-2.el7.x86_64.rpm /tmp/bcl-convert.rpm

RUN yum install -y gdb sendmail && \
    rpm -i /tmp/bcl-convert.rpm && \
    rm /tmp/bcl-convert.rpm && \
    yum clean all && \
    rm -rf /var/cache/yum

ENTRYPOINT ["/usr/local/bin/process_ngs_runs.sh"]