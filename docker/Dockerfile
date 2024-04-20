FROM ubuntu:20.04 as base

ARG DEBIAN_FRONTEND=noninteractive

# UID/GID injection on build if wanted
ARG USER_UID=
ARG USER_GID=

# Name of the regular user. Does not look useful but can save a bit time when changing
ENV QT_USERNAME=qt

# Needed in both builder and qt stages, so has to be defined here
ENV QT_PREFIX=/usr/local

# Install all build dependencies
RUN apt-get update && apt-get -y dist-upgrade && apt-get -y --no-install-recommends install \
	ca-certificates \
	# sudo to be able to modify the container as the user, if needed.
	sudo \
	curl \
	python3 \
	python3-dev\
	gperf \
	bison \
	flex \
	build-essential \
	pkg-config \
	libgl1-mesa-dev \
	libicu-dev \
	firebird-dev \
	libmysqlclient-dev \
	libpq-dev \
	# bc suggested for openssl tests
	bc \
	libssl-dev \
	# git is needed to build openssl in older versions
	git \
	# xcb dependencies
	libfontconfig1-dev \
	libfreetype6-dev \
	libx11-dev \
	libxext-dev \
	libxfixes-dev \
	libxi-dev \
	libxrender-dev \
	libxcb1-dev \
	libx11-xcb-dev \
	libxcb-glx0-dev \
	libxkbcommon-x11-dev \
	libxkbcommon-dev \
	libglu1-mesa-dev \
	libxcb-shm0-dev \
	libxcb-icccm4-dev \
	libxcb-image0-dev \
	libxcb-keysyms1-dev \
	libxcb-render-util0-dev \
	libxcb-xinerama0-dev \
	libxcb-sync-dev \
	libxcb-util-dev \
	x11proto-record-dev \
	libxtst-dev \
	libatspi2.0-dev \
	libatk-bridge2.0-dev \
	# bash needed for argument substitution in entrypoint
	bash \
	# since 5.14.0 we apparently need libdbus-1-dev and libnss3-dev
	libnss3-dev \
	libdbus-1-dev \
	&& apt-get -qq clean \
	&& rm -rf /var/lib/apt/lists/* \
	&& printf "#!/bin/sh\nls -lah" > /usr/local/bin/ll && chmod +x /usr/local/bin/ll

RUN apt-get install '^libxcb.*-dev' libx11-xcb-dev libglu1-mesa-dev libxrender-dev libxi-dev libxkbcommon-dev libxkbcommon-x11-dev -y

RUN apt-get install libx11-* -y
RUN apt-get install libx11* -y

RUN apt-get install libxcb-* -y
RUN apt-get install libxcb* -y

RUN apt-get install libxkbcommon-dev -y

RUN apt-get update && apt-get clean && apt-get install -y build-essential
RUN apt-get install software-properties-common -y
RUN add-apt-repository -y universe
RUN apt-get update

RUN apt install libfontconfig1-dev \
				libfreetype6-dev \
				libx11-dev \
				libx11-xcb-dev \
				libxext-dev \
				libxfixes-dev \
				libxi-dev \
				libxrender-dev \
				libxcb1-dev \
				libxcb-cursor-dev \
				libxcb-glx0-dev \
				libxcb-keysyms1-dev libxcb-image0-dev libxcb-shm0-dev \
				libxcb-icccm4-dev libxcb-sync-dev libxcb-xfixes0-dev \
				libxcb-shape0-dev libxcb-randr0-dev libxcb-render-util0-dev \
				libxcb-util-dev libxcb-xinerama0-dev libxcb-xkb-dev \
				libxkbcommon-dev libxkbcommon-x11-dev -y


# Adding regular user
RUN if [ ${USER_GID} ]; then \
	addgroup -g ${USER_GID} ${QT_USERNAME}; \
	else \
	addgroup ${QT_USERNAME}; \
	fi \
	&& if [ ${USER_UID} ]; then \
	useradd -u ${USER_UID} -g ${QT_USERNAME} ${QT_USERNAME}; \
	else \
	useradd -g ${QT_USERNAME} ${QT_USERNAME}; \
	fi && mkdir /home/${QT_USERNAME}

# make sure the user is able to sudo if needed
RUN adduser ${QT_USERNAME} sudo
RUN echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

# build stage
FROM base as builder

LABEL stage=qt-build-builder

# QT Version
ARG QT_VERSION_MAJOR=5
ARG QT_VERSION_MINOR=11
ARG QT_VERSION_PATCH=3

ENV QT_BUILD_ROOT=/tmp/qt_build

# They switched the tarball naming scheme from 5.9 to 5.10. This ARG shall provide a possibility to reflect that
ARG QT_TARBALL_NAMING_SCHEME=everywhere
# Providing flag for archived or stable versions
ARG QT_DOWNLOAD_BRANCH=official_releases

ENV QT_BUILD_DIR=${QT_BUILD_ROOT}/qt-${QT_TARBALL_NAMING_SCHEME}-src-${QT_VERSION_MAJOR}.${QT_VERSION_MINOR}.${QT_VERSION_PATCH}/build

# Installing from here
WORKDIR ${QT_BUILD_ROOT}

# Download sources
RUN curl -sSL https://download.qt.io/${QT_DOWNLOAD_BRANCH}/qt/${QT_VERSION_MAJOR}.${QT_VERSION_MINOR}/${QT_VERSION_MAJOR}.${QT_VERSION_MINOR}.${QT_VERSION_PATCH}/single/qt-${QT_TARBALL_NAMING_SCHEME}-src-${QT_VERSION_MAJOR}.${QT_VERSION_MINOR}.${QT_VERSION_PATCH}.tar.xz | tar xJ

WORKDIR ${QT_BUILD_DIR}

# Possibility to make outputs less verbose when required for a ci build
ARG CI_BUILD=
ENV CI_BUILD=${CI_BUILD}

# Speeding up make depending of your system
ARG CORE_COUNT=1
ENV CORE_COUNT=${CORE_COUNT}

# Configure, make, install
# before running the configuration, adding a directory to copy additional contents to the final image
ADD configure.sh configure.sh
RUN mkdir /opt/extra-dependencies && chmod +x ./configure.sh && ./configure.sh ${CORE_COUNT} ${CI_BUILD}

COPY build.sh build.sh
RUN ./build.sh ${CI_BUILD} ${CORE_COUNT}

# install it
RUN make install

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# resulting image with environment
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

FROM base as qt

ENV ENTRYPOINT_DIR=/usr/local/bin
ENV APP_BUILDDIR=/var/build

COPY --from=builder ${QT_PREFIX} ${QT_PREFIX}

# the next copy statement failed often. My only guess is, that the extra dependencies are not existent and somehow that
# triggers a failure here.... A workaround for similar issues is to put an empty run statement in between: https://github.com/moby/moby/issues/37965
RUN true
COPY --from=builder /opt/extra-dependencies /opt/extra-dependencies

#for modifications during configuration
ENV LD_LIBRARY_PATH=/opt/extra-dependencies/lib:${LD_LIBRARY_PATH}

# the next copy statement failed often. My only guess is, that the extra dependencies are not existent and somehow that
# triggers a failure here.... A workaround for similar issues is to put an empty run statement in between: https://github.com/moby/moby/issues/37965

# VTK Installation
RUN apt-get update && apt-get install -y libvtk7-dev libboost-all-dev

# OpenCV Installation
RUN apt-get install -y libopencv-dev python3-opencv libopencv-contrib-dev wget unzip cmake libeigen3-dev libflann-dev

# PCL Installation

ARG PCL_VERSION="1.12.0"
RUN wget https://github.com/PointCloudLibrary/pcl/archive/refs/tags/pcl-1.12.0.zip 
RUN unzip pcl-1.12.0.zip
WORKDIR /pcl-pcl-1.12.0
RUN mkdir build
WORKDIR /pcl-pcl-1.12.0/build
RUN cmake ..
RUN make -j8 

WORKDIR /home/${QT_USERNAME}

# RUN true
# COPY entrypoint.sh ${ENTRYPOINT_DIR}

# RUN chmod +x ${ENTRYPOINT_DIR}/entrypoint.sh

# VOLUME ["${APP_BUILDDIR}"]

# USER ${QT_USERNAME}

# ENTRYPOINT ["entrypoint.sh"]


