//
//  ContentView.swift
//  cocoaheadsTalk
//
//  Created by Gerald Kim on 8/10/19.
//  Copyright © 2019 ARPlaykit. All rights reserved.
//

import SwiftUI
import RealityKit
import ARKit

enum ARMode {
    case box
    case sphere
    case plane
    case face
    case load
}

struct ContentView : View {
    @State var mode: ARMode = .load

    var body: some View {
        ZStack(alignment: .bottom) {
            ARViewContainer(mode: $mode).edgesIgnoringSafeArea(.all)
            HStack {
                Button(action: {
                    self.mode = .box
                }, label: {
                    Text("Box")
                })
                Button(action: {
                    self.mode = .sphere
                }, label: {
                    Text("Sphere")
                })
                Button(action: {
                    self.mode = .plane
                }, label: {
                    Text("Plane")
                })
                Button(action: {
                    self.mode = .face
                }, label: {
                    Text("Face")
                })
            }
        }
    }
}

struct ARViewContainer: UIViewRepresentable {

    @Binding var mode: ARMode

    func makeUIView(context: Context) -> ARView {
        
        let arView = ARView(frame: .zero)
        arView.session.delegate = context.coordinator
        arView.debugOptions = [.showFeaturePoints, .showWorldOrigin]

        return arView
    }

    func updateUIView(_ uiView: ARView, context: Context) {
        uiView.scene.anchors.forEach {
            $0.removeFromParent()
        }
        switch mode {
        case .box:
            let configuration = ARWorldTrackingConfiguration()
            configuration.planeDetection = [.horizontal]
            uiView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
            addBoxAnchor(arView: uiView)
        case .sphere:
            let configuration = ARWorldTrackingConfiguration()
            uiView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
            addSphereInSpace(arView: uiView)
        case .plane:
            let configuration = ARWorldTrackingConfiguration()
            configuration.planeDetection = [.horizontal]
            uiView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
            addPlaneToPlane(arView: uiView)
        case .face:
            let configuration = ARFaceTrackingConfiguration()
            uiView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
            uiView.scene.addAnchor(faceAnchor)
        default:
            break
        }
    }

    func addBoxAnchor(arView: ARView) {
        // Load the "Box" scene from the "Experience" Reality File
        let boxAnchor = try! Experience.loadBox()

        // Add the box anchor to the scene
        arView.scene.anchors.append(boxAnchor)
    }

    func addSphereInSpace(arView: ARView) {
        let anchor = AnchorEntity(world: SIMD3<Float>(-0.3, -0.3, 0))
        let mesh = MeshResource.generateSphere(radius: 0.2)
        let material = SimpleMaterial(color: .red, isMetallic: true)
        let sphere = ModelEntity(mesh: mesh, materials: [material])
        sphere.position.z = -1.0
        anchor.addChild(sphere)

        arView.scene.addAnchor(anchor)
    }

    func addPlaneToPlane(arView: ARView) {
        let planeAnchor = AnchorEntity(plane: .horizontal, minimumBounds: [0.1, 0.1])
        let plane = try! Entity.load(named: "toy_biplane")
        planeAnchor.addChild(plane)
        arView.scene.addAnchor(planeAnchor)
    }

    let faceAnchor = AnchorEntity()

    func makeCoordinator() -> ARDelegateHandler {
        ARDelegateHandler(anchor: faceAnchor)
    }

    class ARDelegateHandler: NSObject, ARSessionDelegate {
        let faceAnchor: AnchorEntity

        init(anchor: AnchorEntity) {
            self.faceAnchor = anchor
            super.init()
        }

        func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
            for anchor in anchors {
                guard let anchor = anchor as? ARFaceAnchor else { continue }

                let leftPosition = simd_make_float3(simd_mul(anchor.transform, anchor.leftEyeTransform).columns.3)
                let rightPosition = simd_make_float3(simd_mul(anchor.transform, anchor.rightEyeTransform).columns.3)

                let mesh = MeshResource.generateSphere(radius: 0.02)
                let redMaterial = SimpleMaterial(color: .red, isMetallic: true)
                let leftSphere = ModelEntity(mesh: mesh, materials: [redMaterial])
                leftSphere.position = leftPosition
                faceAnchor.addChild(leftSphere)

                let greenMaterial = SimpleMaterial(color: .green, isMetallic: true)
                let rightSphere = ModelEntity(mesh: mesh, materials: [greenMaterial])
                rightSphere.position = rightPosition
                faceAnchor.addChild(rightSphere)
            }
        }
    }
}

#if DEBUG
struct ContentView_Previews : PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
#endif
