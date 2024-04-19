FROM ubuntu:22.04 as base

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
	libxcb-shm0-dev \
	libxcb-icccm4-dev \
	libxcb-image0-dev \
	libxcb-keysyms1-dev \
	libxcb-render-util0-dev \
	libxcb-xinerama0-dev \
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
RUN mkdir /opt/extra-dependencies && chmod +x ./configure.sh && ./configure.sh ${CORE_COUNT} ${CI_BUILD}

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

# OpenCV Installation

ARG OPENCV_VERSION="4.8.0"
RUN apt-get clean && \
    apt-get update && \
    apt-get install -y --no-install-recommends --fix-missing \
        build-essential binutils \
        ca-certificates cmake cmake-qt-gui curl \
        dbus-x11 \
        ffmpeg \
        gdb gcc g++ gfortran git \
        tar \
        lsb-release \
        procps \
        manpages-dev \
        unzip \
        zip \
        wget \
        xauth \
        swig \
        python3-pip python3-dev python3-numpy python3-distutils \
        python3-setuptools python3-pyqt5 python3-opencv \
        libboost-python-dev libboost-thread-dev libatlas-base-dev libavcodec-dev \
        libavformat-dev libavutil-dev libcanberra-gtk3-module libeigen3-dev \
        libglew-dev libgl1-mesa-dev libgl1-mesa-glx libglib2.0-0 libgtk2.0-dev \
        libgtk-3-dev libjpeg-dev libjpeg8-dev libjpeg-turbo8-dev liblapack-dev \
        liblapacke-dev libopenblas-dev libopencv-dev libpng-dev libpostproc-dev \
        libpq-dev libsm6 libswscale-dev libtbb-dev libtbb2 libtesseract-dev \
        libtiff-dev libtiff5-dev libv4l-dev libx11-dev libxext6 libxine2-dev \
        libxrender-dev libxvidcore-dev libx264-dev libgtkglext1 libgtkglext1-dev \
        libgstreamer-plugins-base1.0-dev libglx-dev \ 
        libgstreamer1.0-dev libopenexr-dev libqt5svg5-dev qt5-default \
        openexr \
        pkg-config \
        qv4l2 \
        v4l-utils \
        zlib1g-dev \
        locales \
        && locale-gen en_US.UTF-8 \
        && LC_ALL=en_US.UTF-8 \
        && rm -rf /var/lib/apt/lists/* \
        && apt-get clean

WORKDIR /opencv
RUN wget -O opencv.zip https://github.com/opencv/opencv/archive/${OPENCV_VERSION}.zip \
    && wget -O opencv_contrib.zip https://github.com/opencv/opencv_contrib/archive/${OPENCV_VERSION}.zip \
    && unzip opencv.zip \
    && unzip opencv_contrib.zip \
    && mv opencv-${OPENCV_VERSION} opencv \
    && mv opencv_contrib-${OPENCV_VERSION} opencv_contrib

RUN mkdir /opencv/opencv/build
WORKDIR /opencv/opencv/build

RUN cmake -D CMAKE_BUILD_TYPE=RELEASE \
    -D CMAKE_INSTALL_PREFIX=/usr/local \
    -D OPENCV_EXTRA_MODULES_PATH=/opencv/opencv_contrib/modules ..

RUN make -j$(nproc)
RUN make install
RUN ldconfig

# PCL Installation

ARG PCL_VERSION="1.12.0"
RUN wget https://github.com/PointCloudLibrary/pcl/archive/refs/tags/pcl-1.12.0.zip
RUN unzip pcl-pcl-1.12.0.zip
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

USER ${QT_USERNAME}

# ENTRYPOINT ["entrypoint.sh"]