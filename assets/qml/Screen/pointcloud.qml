import QtQuick 2.4
import QtQuick.Controls 1.3
import QtQuick.Layouts 1.1
import QtGraphicalEffects 1.0
import QtQuick.Scene3D 2.0
import Qt3D.Core 2.0 as Q3D
import Qt3D.Render 2.0
import Qt3D.Input 2.0
import Qt3D.Extras 2.0

import pcl 1.0

ApplicationWindow {
    id: window
    title: qsTr("Map Visualization")
    width: 1200
    height: 800
    visible: true

    PointCloudLoader {
        id: readerBunny
        filename: "/home/lacie/Github/GreenHouseAR/assest/data/hand_gestures/hand_0/image_0002.pcd"
    }
    PointCloudLoader {
        id: readerBunnyNormal
        filename: "/home/lacie/Github/GreenHouseAR/assest/data/bunny_normal.pcd"
    }

    GridLayout {
        anchors.fill: parent
        Scene3D {
            id: scene3d
            Layout.minimumWidth: 50
            Layout.fillWidth: true
            Layout.fillHeight: true
            aspects: ["input", "logic"]
            cameraAspectRatioMode: Scene3D.AutomaticAspectRatio
            focus: true
            Q3D.Entity {
                id: sceneRoot

                Camera {
                    id: mainCamera
                    projectionType: CameraLens.PerspectiveProjection
                    fieldOfView: 75
                    aspectRatio: scene3d.width/scene3d.height
                    nearPlane : 0.1
                    farPlane : 1000.0
                    position: Qt.vector3d( 0.0, 0.0, -20.0 )
                    upVector: Qt.vector3d( 0.0, 1.0, 0.0 )
                    viewCenter: Qt.vector3d( 0.0, 0.0, 0.0 )
                }

                // FirstPersonCameraController {
                OrbitCameraController {
                    camera: mainCamera
                    linearSpeed: 50.0
                    lookSpeed: 50.0
                }

                components: [
                    RenderSettings {
                        activeFrameGraph: Viewport {
                            id: viewport
                            normalizedRect: Qt.rect(0.0, 0.0, 1.0, 1.0) // From Top Left
                            RenderSurfaceSelector {
                                CameraSelector {
                                    id : cameraSelector
                                    camera: mainCamera
                                    FrustumCulling {
                                        ClearBuffers {
                                            buffers : ClearBuffers.ColorDepthBuffer
                                            clearColor: "white"
                                            NoDraw {}
                                        }
                                        LayerFilter {
                                            layers: solidLayer
                                        }
                                        LayerFilter {
                                            layers: pointLayer
                                            RenderStateSet {
                                                renderStates: [
                                                    // If this is uncommented, following pointsizes are ignored in Qt5.7
                                                    PointSize { sizeMode: PointSize.Fixed; value: 3.0 }, // exception when closing application in qt 5.7. Moreover PointSize
                                                    PointSize { sizeMode: PointSize.Programmable }, //supported since OpenGL 3.2
                                                    DepthTest { depthFunction: DepthTest.Less },
                                                    ColorMask { blueMasked: true; redMasked: true; greenMasked: true; alphaMasked: false}
                                                ]
                                            }
                                        }
                                        LayerFilter {
                                            layers: surfelLayer
                                            RenderStateSet {
                                                renderStates: [
                                                    PointSize { sizeMode: PointSize.Programmable }, //supported since OpenGL 3.2
                                                    DepthTest { depthFunction: DepthTest.Less }
                                                    //DepthMask { mask: true }
                                                ]
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    },
                    // Event Source will be set by the Qt3DQuickWindow
                    InputSettings {
                        eventSource: window
                        enabled: true
                    }
                ]

                PhongMaterial {
                    id: phongMaterial
                }


                Layer {
                    id: solidLayer
                }
                Layer {
                    id: pointLayer
                }

                Layer {
                    id: surfelLayer
                }

                Q3D.Entity {
                    id: pointcloud
                    property var meshTransform: Q3D.Transform {
                            id: pointcloudTransform
                            // property real userAngle: rotator.rotationAnimation
                            scale: 20
                            translation: Qt.vector3d(0, -2, 0)
                            // rotation: fromAxisAndAngle(Qt.vector3d(0, 1, 0), userAngle)
                        }
                    property GeometryRenderer pointcloudMesh: GeometryRenderer {
                            geometry: PointCloudGeometry { pointCloud: readerBunny.pointCloud }
                            primitiveType: GeometryRenderer.Points
                        }

                    property Material materialPoint: Material {
                        effect: Effect {
                            techniques: Technique {
                                renderPasses: RenderPass {
                                    shaderProgram: ShaderProgram {
                                        vertexShaderCode: loadSource("qrc:/shader/shader/pointcloud.vert")
                                        fragmentShaderCode: loadSource("qrc:/shader/shader/pointcloud.frag")
                                    }
                                }
                            }
                        }
                        parameters: Parameter { name: "pointSize"; value: 3 }
                    }

                    //property Material materialPoint: PerVertexColorMaterial {}
                    components: [ pointcloudMesh, materialPoint, meshTransform, pointLayer ]
                }
            }
        }
    }

    SystemPalette {
        id: palette
    }
}
