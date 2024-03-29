ARG ROCKY_LINUX_VERSION=9.2
# ------------------------------------------------------------------------
# Build stage
FROM azul/zulu-openjdk:17 as builder

RUN apt-get update && apt-get install -y --no-install-recommends \
  procps \
  unzip \
  && rm -rf /var/lib/apt/lists/*

COPY triskell-nuxeo-server-*.zip /tmp/nuxeo-distribution-tomcat.zip

ENV NUXEO_HOME=/distrib

RUN mkdir -p /tmp/nuxeo-distribution \
  && unzip -q -d /tmp/nuxeo-distribution /tmp/nuxeo-distribution-tomcat.zip \
  && DISTDIR=$(/bin/ls /tmp/nuxeo-distribution | head -n 1) \
  && mv /tmp/nuxeo-distribution/$DISTDIR $NUXEO_HOME \
  && sed -i -e "s/^org.nuxeo.distribution.package.*/org.nuxeo.distribution.package=docker/" $NUXEO_HOME/templates/common/config/distribution.properties \
  # Make sure the packages/* directories belong to nuxeo, to avoid a permission issue with nuxeoctl mp-install
  # in case they are mounted as a volume (then owned by root:root)
  && mkdir -p $NUXEO_HOME/packages/backup \
  && mkdir -p $NUXEO_HOME/packages/store \
  && mkdir -p $NUXEO_HOME/packages/tmp \
  && rm -rf /tmp/nuxeo-distribution* \
  && chmod +x $NUXEO_HOME/bin/*ctl $NUXEO_HOME/bin/*.sh \
  && chmod -R g+rwX $NUXEO_HOME

# ------------------------------------------------------------------------
# Target stage
FROM rockylinux:$ROCKY_LINUX_VERSION

ARG BUILD_TAG
ARG SCM_REF
ARG VERSION

ARG ROCKY_LINUX_VERSION=9.2
ARG LIBREOFFICE_VERSION=7.4.2
ARG GHOSTSCRIPT_MAJOR_VERSION=9
ARG GHOSTSCRIPT_MINOR_VERSION=25
ARG GHOSTSCRIPT_VERSION=$GHOSTSCRIPT_MAJOR_VERSION.$GHOSTSCRIPT_MINOR_VERSION

LABEL org.nuxeo.base.build-tag=$BUILD_TAG
LABEL org.nuxeo.base.scm-ref=$SCM_REF
LABEL org.nuxeo.base.version=$VERSION
# Override parent ones
LABEL org.label-schema.build-date=""
LABEL org.label-schema.license="Apache 2.0"
LABEL org.label-schema.name="Nuxeo Base"
LABEL org.label-schema.vendor="Nuxeo"
LABEL org.opencontainers.image.created=""
LABEL org.opencontainers.image.licenses="Apache 2.0"
LABEL org.opencontainers.image.title="Nuxeo Base"
LABEL org.opencontainers.image.vendor="Nuxeo"

# Configure Zulu Repository
RUN rpm --import http://repos.azulsystems.com/RPM-GPG-KEY-azulsystems \
  && rpm --install https://cdn.azul.com/zulu/bin/zulu-repo-1.0.0-1.noarch.rpm

RUN dnf -y update \
  && dnf -y --setopt=skip_missing_names_on_install=False install \
    epel-release \
    # install java first to provide it for depend packages (such as libreoffice)
    zulu17-jdk \
    # find is not included in the base rockylinux image
    findutils \
    # install gzip first to allow using tar
    gzip \
  # install libreoffice
  && curl -f -L https://packages.nuxeo.com/repository/document-foundation-raw/LibreOffice_${LIBREOFFICE_VERSION}_Linux_x86-64_rpm.tar.gz | tar -C /tmp -xzv \
  && dnf -y localinstall /tmp/LibreOffice_${LIBREOFFICE_VERSION}*/RPMS/*.rpm \
  && ln -s /opt/libreoffice$(echo $LIBREOFFICE_VERSION | cut -f 1,2 -d ".")/program/soffice /usr/bin/soffice \
  && rm -rf /tmp/LibreOffice_${LIBREOFFICE_VERSION}* \
  # install older version of ghostscript to avoid breaking changes on EPS to PDF conversion
  && curl -f -L https://github.com/ArtifexSoftware/ghostpdl-downloads/releases/download/gs$GHOSTSCRIPT_MAJOR_VERSION$GHOSTSCRIPT_MINOR_VERSION/ghostscript-$GHOSTSCRIPT_VERSION-linux-x86_64.tgz | tar -xzv \
  && mv ghostscript-$GHOSTSCRIPT_VERSION-linux-x86_64/gs-$GHOSTSCRIPT_MAJOR_VERSION$GHOSTSCRIPT_MINOR_VERSION-linux-x86_64 /usr/bin/gs \
  && rm -rf ghostscript-$GHOSTSCRIPT_VERSION-linux-x86_64 \
  # ImageMagick 7 for Rocky Linux 9 is only provided by a third party repo
  && dnf -y install https://rpms.remirepo.net/enterprise/remi-release-$ROCKY_LINUX_VERSION.rpm \
  && dnf -y --enablerepo=remi install ImageMagick7 \
  # devel repository required for some packages such as libwpd-tools
  && dnf -y --setopt=skip_missing_names_on_install=False --enablerepo=devel install \
    libwpd-tools \
    # required by exiftool to extract binary metadata from open office document
    perl-Archive-Zip \
    poppler-utils \
    # ps is not included in the base rockylinux image
    procps \
    unzip \
    wget \
    # Add CJK fonts
    google-noto-cjk-fonts-common \
  && dnf clean all

# Remove perl-Net-SSLeay example private key
RUN rm /usr/share/doc/perl-Net-SSLeay/examples/server_key.pem

# Remove setuid/setgid binaries from images for security
RUN find / -ignore_readdir_race -perm 6000 -type f -exec chmod a-s {} \; || true

# Set an UTF-8 LANG
RUN dnf -y install glibc-langpack-en
ENV LANG en_US.utf8


# Add a nuxeo user with a fixed UID
# We chose an arbitrary UID that doesn't conflict with possibly existing users
ENV NUXEO_USER nuxeo
RUN useradd -m -d /home/$NUXEO_USER -u 900 -s /bin/bash $NUXEO_USER

ENV NUXEO_HOME /opt/nuxeo/server
ENV NUXEO_CONF /etc/nuxeo/nuxeo.conf

# Set permissions on writeable directories to support arbitrary user IDs for OpenShift.
# These directories must be owned by the root group and be readable/writable by that group.
# See https://docs.openshift.com/container-platform/3.5/creating_images/guidelines.html#use-uid
RUN mkdir -p $NUXEO_HOME \
  # Create folders until `nuxeo.war` to allow it to be mounted
  && mkdir -p $NUXEO_HOME/nxserver/nuxeo.war \
  && chown 900:0 $NUXEO_HOME && chmod g+rwX $NUXEO_HOME \
  && mkdir -p /etc/nuxeo \
  && chown 900:0 /etc/nuxeo && chmod g+rwX /etc/nuxeo \
  && mkdir -p /var/lib/nuxeo \
  && chown 900:0 /var/lib/nuxeo && chmod g+rwX /var/lib/nuxeo \
  && mkdir -p /var/log/nuxeo \
  && chown  900:0 /var/log/nuxeo && chmod g+rwX /var/log/nuxeo \
  && mkdir -p /var/pid/nuxeo \
  && chown 900:0 /var/pid/nuxeo && chmod g+rwX /var/pid/nuxeo \
  && chmod g=u /etc/passwd

COPY docker-entrypoint.sh /

# Copy packages installation script
COPY install-packages.sh /

# Copy script to run Nuxeo in dev environment
COPY nuxeo-run-dev.sh /

# Create directory in which to mount property files appended to nuxeo.conf at runtime
RUN mkdir /etc/nuxeo/conf.d
# Copy base property files.
COPY conf.d /etc/nuxeo/conf.d/

# Create directory in which to copy shell scripts to run at runtime
RUN mkdir /docker-entrypoint-initnuxeo.d && chmod g+rwx,o+rx /docker-entrypoint-initnuxeo.d \
  && chmod -R g+rwX,o+rX /etc/nuxeo/conf.d \
  && chmod g+rwx,o+rx /docker-entrypoint.sh \
  && chmod g+rwx,o+rx /install-packages.sh

# Copy Nuxeo distribution
COPY --from=builder /distrib $NUXEO_HOME

# Work around missing support for --chown flag with COPY instruction in Kaniko
# TODO NXP-28052: remove and use COPY --chown when fixed in Kaniko, or find a proper way
RUN chown -R 900:0 $NUXEO_HOME \
  && chmod -R g+rwX $NUXEO_HOME

VOLUME /var/lib/nuxeo
VOLUME /var/log/nuxeo
VOLUME /tmp

ENV PATH $NUXEO_HOME/bin:$PATH

EXPOSE 8080
EXPOSE 8787
ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["nuxeoctl", "console"]

# Run as a non root user with a fixed UID
USER 900

