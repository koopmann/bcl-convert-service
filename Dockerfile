FROM centos:7

# Add a user with UID 1000
RUN useradd -u 1000 -m user1000

# Update CentOS repository URLs
RUN sed -i s/mirror.centos.org/vault.centos.org/g /etc/yum.repos.d/CentOS-*.repo
RUN sed -i s/^#.*baseurl=http/baseurl=http/g /etc/yum.repos.d/CentOS-*.repo
RUN sed -i s/^mirrorlist=http/#mirrorlist=http/g /etc/yum.repos.d/CentOS-*.repo

# Add bcl-convert RPM using environment variable
ARG BCL_CONVERT_RPM
ADD ${BCL_CONVERT_RPM} /tmp/bcl-convert.rpm

# Install dependencies and bcl-convert
RUN yum install -y gdb rsync mailx python3 && \
    rpm -i /tmp/bcl-convert.rpm && \
    rm /tmp/bcl-convert.rpm && \
    yum clean all && \
    rm -rf /var/cache/yum

# Copy the Python email script
COPY send_email.py /usr/local/bin/send_email.py

# Copy the main script and ensure it is executable
COPY process_ngs_runs.sh /usr/local/bin/process_ngs_runs.sh
RUN chmod +x /usr/local/bin/process_ngs_runs.sh

# Set the default entrypoint to run the process_ngs_runs.sh script
ENTRYPOINT ["/usr/local/bin/process_ngs_runs.sh"]