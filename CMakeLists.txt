cmake_minimum_required(VERSION 3.21)
project(SimpleSfMViz)

set(CMAKE_CXX_STANDARD 11)
SET(COMPILE_FLAGS "-m64 -std=c++11 -Wall -Wextra -pedantic")
SET( CMAKE_CXX_FLAGS  "${CMAKE_CXX_FLAGS} ${COMPILE_FLAGS}" )

add_compile_options("-march=native")

set(CMAKE_INCLUDE_CURRENT_DIR ON)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

set(CMAKE_AUTOUIC ON)
set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)

list(APPEND QML_IMPORT_PATH "/home/lacie/Qt/5.15.2/gcc_64/qml")
set(CMAKE_PREFIX_PATH "/home/lacie/Qt/5.15.2/gcc_64")

set(QML_IMPORT_PATH ${QML_IMPORT_PATH}
    CACHE STRING "Qt Creator 4.1 extra qml import paths"
    FORCE
)

list( APPEND CMAKE_MODULE_PATH ${PROJECT_SOURCE_DIR}/cmake_modules)

# ROS package
## Add include directories
include_directories(/opt/ros/noetic/include /opt/ros/noetic/lib)

include_directories(
    ${CMAKE_CURRENT_SOURCE_DIR}/thirdparty/
    # ${CMAKE_CURRENT_SOURCE_DIR}/thirdparty/SimpleSfM/include/
    ${CMAKE_CURRENT_SOURCE_DIR}/thirdparty/SQLite/
    )

add_subdirectory(thirdparty)

set(GLEW_USE_STATIC_LIBS OFF)
add_definitions( -DGLEW_STATIC )

set(WITH_PCL OFF  CACHE BOOL "Enable PCL")
set(WITH_OPENGL ON CACHE BOOL "Enable OpenGL")

set(GLEW_VERBOSE ON)
include(FindGLEW)
find_package(GLEW REQUIRED)
if(GLEW_FOUND)
    include_directories(${GLEW_INCLUDE_DIR})
    link_libraries(${GLEW_LIBRARIES})
endif(GLEW_FOUND)

find_package(glfw3 REQUIRED)
find_package(OpenGL REQUIRED)

if(OpenGL_FOUND)
    include_directories(${OPENGL_INCLUDE_DIR})
endif(OpenGL_FOUND)

find_package(GLUT REQUIRED)
include_directories(${GLUT_INCLUDE_DIRS})

find_package(GLM)
include_directories(${GLM_INCLUDE_DIRS})
link_directories(${GLM_LIBRARY_DIRS})
add_definitions(${GLM_DEFINITIONS})

## GTSAM SfM
find_package(Boost COMPONENTS thread filesystem date_time system REQUIRED)
# find_package(GTSAM REQUIRED)
find_package(OpenCV REQUIRED)
find_package(Eigen3 REQUIRED)

include_directories(${OpenCV_INCLUDE_DIRS})
include_directories(${Boost_INCLUDE_DIR})
# include_directories(${GTSAM_INCLUDE_DIR})
include_directories(${EIGEN3_INCLUDE_DIR})


find_package(Qt5Core REQUIRED)
find_package(Qt5Quick REQUIRED)

find_package(Qt5Qml REQUIRED)
find_package(Qt5Widgets REQUIRED)
find_package(Qt5Gui REQUIRED)
find_package(Qt5Concurrent REQUIRED)

find_package(Qt53DInput REQUIRED)
find_package(Qt53DQuick REQUIRED)
find_package(Qt53DRender REQUIRED)
find_package(Qt53DQuickRender REQUIRED)

include_directories(${Qt5Widgets_INCLUDE_DIRS} ${QtQml_INCLUDE_DIRS})
add_definitions(${Qt5Widgets_DEFINITIONS} ${QtQml_DEFINITIONS} ${${Qt5Quick_DEFINITIONS}})

# PCL Library
find_package(PCL REQUIRED COMPONENTS common io)
link_directories(${PCL_LIBRARY_DIRS})

include_directories(${CMAKE_CURRENT_SOURCE_DIR}/include/Model
                    ${CMAKE_CURRENT_SOURCE_DIR}/include/Plugin
                    ${CMAKE_CURRENT_SOURCE_DIR}/include/View
                    ${CMAKE_CURRENT_SOURCE_DIR}/include/Handler
                    ${CMAKE_CURRENT_SOURCE_DIR}/include/Common
                    ${CMAKE_CURRENT_SOURCE_DIR}/include)

file(GLOB HEADERS ${CMAKE_CURRENT_SOURCE_DIR}/include/Model/*.h
                      ${CMAKE_CURRENT_SOURCE_DIR}/include/Plugin/*.h
                      ${CMAKE_CURRENT_SOURCE_DIR}/include/View/*.h
                      ${CMAKE_CURRENT_SOURCE_DIR}/include/Handler/*.h
                      ${CMAKE_CURRENT_SOURCE_DIR}/include/Plugin/OpenGL/*.h
                    #   ${CMAKE_CURRENT_SOURCE_DIR}/include/Plugin/SfM/*.h
                      ${CMAKE_CURRENT_SOURCE_DIR}/include/Plugin/Camera/*.h
                      ${CMAKE_CURRENT_SOURCE_DIR}/include/Plugin/DataVisualize/*.h
                      ${CMAKE_CURRENT_SOURCE_DIR}/include/Common/*.h
                      ${CMAKE_CURRENT_SOURCE_DIR}/include/*.h)

file(GLOB SOURCES ${CMAKE_CURRENT_SOURCE_DIR}/src/Model/*.cpp
                      ${CMAKE_CURRENT_SOURCE_DIR}/src/Handler/*.cpp
                      ${CMAKE_CURRENT_SOURCE_DIR}/src/Plugin/*.cpp
                      ${CMAKE_CURRENT_SOURCE_DIR}/src/Plugin/OpenGL/*.cpp
                    #   ${CMAKE_CURRENT_SOURCE_DIR}/src/Plugin/SfM/*.cpp
                      ${CMAKE_CURRENT_SOURCE_DIR}/src/Plugin/Camera/*.cpp
                      ${CMAKE_CURRENT_SOURCE_DIR}/src/Plugin/DataVisualize/*.cpp
                      ${CMAKE_CURRENT_SOURCE_DIR}/src/View/*.cpp
                      ${CMAKE_CURRENT_SOURCE_DIR}/src/Common/*.cpp
                      ${CMAKE_CURRENT_SOURCE_DIR}/src/*.cpp)

source_group("Header Files" FILES ${HEADERS})
source_group("Source Files" FILES ${SOURCES})

qt5_add_resources(QT_RESOURCES ${CMAKE_CURRENT_SOURCE_DIR}/assets/qml.qrc)

add_executable(${PROJECT_NAME}
                ${HEADERS}
                ${SOURCES}
                ${QT_RESOURCES}
                )

target_compile_definitions(${PROJECT_NAME}
                PRIVATE $<$<OR:$<CONFIG:Debug>,$<CONFIG:RelWithDebInfo>>:QT_QML_DEBUG>)


target_link_libraries(${PROJECT_NAME} ${OPENGL_LIBRARY}
                                        glfw
                                        GLEW::GLEW
                                        Qt5::Core
                                        Qt5::Quick
                                        Qt5::Qml
                                        Qt5::Widgets
                                        Qt5::Concurrent
                                        ${PCL_LIBRARIES}
                                        stdc++
                                        ${Boost_LIBRARIES}
                                        ${OpenCV_LIBS}
                                        # -lgtsam
                                        -ltbb
                                        -I/opt/ros/noetic/include
                                        -L/opt/ros/noetic/lib
                                        # SimpleSfM_lib
                                        sqlite3
                                        -lpthread
                                        dl
                                        )

target_include_directories(${PROJECT_NAME} PRIVATE PRIVATE ${PCL_INCLUDE_DIRS})
target_compile_definitions(${PROJECT_NAME} PUBLIC WITH_PCL=1)

qt5_use_modules(${PROJECT_NAME} Qml Widgets Quick 3DCore 3DQuick 3DRender 3DQuickRender)

file(COPY ${CMAKE_CURRENT_SOURCE_DIR}/assets
     DESTINATION ${CMAKE_CURRENT_BINARY_DIR})

