#!/bin/bash

set -e

docker build --build-arg QT_VERSION_MAJOR=5 \
             --build-arg QT_VERSION_MINOR=15 \
             --build-arg QT_VERSION_PATCH=2 \
             --build-arg CORE_COUNT=12 \
             --target=qt -t simple_viz:5.15.2 \
             .



