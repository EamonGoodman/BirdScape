//
//  ContentView.swift
//  OneButtonAR
//
//  Created by Nien Lam on 9/8/21.
//  Modified by Eamon Goodman on 5/2/22.
//

import SwiftUI
import ARKit
import RealityKit
import Combine
import AVFoundation

class ViewModel: ObservableObject {
    let uiSignal = PassthroughSubject<UISignal, Never>()

    enum UISignal {
//        case screenTapped
        case reset
    }
}

struct ContentView : View {
    @StateObject var viewModel = ViewModel()

    var body: some View {
        ZStack {
            ARViewContainer(viewModel: viewModel)
                .onTapGesture {
//                    viewModel.uiSignal.send(.screenTapped)
                }

            Button {
                viewModel.uiSignal.send(.reset)
            } label: {
                Label("Reset", systemImage: "gobackward")
                    .font(.system(.title))
                    .foregroundColor(.white)
                    .labelStyle(IconOnlyLabelStyle())
                    .frame(width: 44, height: 44)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
            .padding()
        }
        .edgesIgnoringSafeArea(.all)
        .statusBar(hidden: true)
    }
}

struct ARViewContainer: UIViewRepresentable {
    let viewModel: ViewModel

    func makeUIView(context: Context) -> ARView {
        SimpleARView(frame: .zero, viewModel: viewModel)
    }
    
    func updateUIView(_ uiView: ARView, context: Context) {}
}


class SimpleARView: ARView {
    var viewModel: ViewModel
    var arView: ARView { return self }
    var originAnchor: AnchorEntity!
    var pov: AnchorEntity!
    var subscriptions = Set<AnyCancellable>()

    var bluejay: ModelEntity!
    var cardinal: ModelEntity!
    var hairy: ModelEntity!
    var herring: ModelEntity!
    var redtail: ModelEntity!
    
    var bluejayEnt:     ModelEntity!
    var cardinalEnt:    ModelEntity!
    var hairyEnt:       ModelEntity!
    var herringEnt:     ModelEntity!
    var redtailEnt:     ModelEntity!
    
    var bluejayPlayer: AudioPlaybackController? = nil
    var cardinalPlayer: AudioPlaybackController? = nil
    var hairyPlayer: AudioPlaybackController? = nil
    var herringPlayer: AudioPlaybackController? = nil
    var redtailPlayer: AudioPlaybackController? = nil

    
    var player: AVAudioPlayer!

    
    var objid = 0
    

    
    // bounce toggle for animation
    var upDnToggle = false

    init(frame: CGRect, viewModel: ViewModel) {
        self.viewModel = viewModel
        super.init(frame: frame)
    }
    
    required init?(coder decoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    required init(frame frameRect: CGRect) {
        fatalError("init(frame:) has not been implemented")
    }
    
    override func didMoveToSuperview() {
        super.didMoveToSuperview()

        UIApplication.shared.isIdleTimerDisabled = true
        
        setupScene()
    }


    func setupScene() {
        // Create an anchor at scene origin.
        originAnchor = AnchorEntity(world: .zero)
        arView.scene.addAnchor(originAnchor)
        
        // Add pov entity that follows the camera.
        pov = AnchorEntity(.camera)
        arView.scene.addAnchor(pov)

        // Setup world tracking.
        let configuration = ARWorldTrackingConfiguration()
        configuration.environmentTexturing = .automatic
        arView.session.run(configuration)
        
        // Called every frame.
        scene.subscribe(to: SceneEvents.Update.self) { event in
            
            // Call renderLoop method on every frame.
            self.renderLoop()
        }.store(in: &subscriptions)
        
        viewModel.uiSignal.sink { [weak self] in
            self?.processUISignal($0)
        }.store(in: &subscriptions)
        
        loadModels()
        loadAudio()
    }

    func processUISignal(_ signal: ViewModel.UISignal) {
        switch signal {

        case .reset:
            originAnchor.children.removeAll()
            loadModels()
            loadAudio()
        }
    }
    
    
    func loadModels() {
        
        bluejayEnt = ModelEntity()
        originAnchor.addChild(bluejayEnt)
        bluejayEnt.position = [-1, 0, -1]
        bluejay = try! Entity.loadModel(named: "blue_jay.usdz")
        bluejay.scale = SIMD3(repeating: 0.003)
        bluejayEnt.addChild(bluejay)
        makeSonos(parent: bluejayEnt, name: "bluejay.png")
        makeText(parent: bluejayEnt, text: "Blue Jay")
        bluejayEnt.generateCollisionShapes(recursive: true)
        arView.installGestures([.all], for: bluejayEnt)

        cardinalEnt = ModelEntity()
        originAnchor.addChild(cardinalEnt)
        cardinalEnt.position = [-0.5, 0, -1]
        cardinal = try! Entity.loadModel(named: "cardinal.usdz")
        cardinal.position.y = 0.02
        cardinal.scale = SIMD3(repeating: 0.0004)
        cardinal.orientation = simd_quatf(angle: (3.1415 / 3), axis: [0, 1, 0])
        cardinalEnt.addChild(cardinal)
        makeSonos(parent: cardinalEnt, name: "cardinal.png")
        makeText(parent: cardinalEnt, text: "Northern Cardinal")
        cardinalEnt.generateCollisionShapes(recursive: true)
        arView.installGestures([.all], for: cardinalEnt)

        hairyEnt = ModelEntity()
        originAnchor.addChild(hairyEnt)
        hairyEnt.position = [0, 0.0, -1]
        hairy = try! Entity.loadModel(named: "hairy_woodpecker_2.usdz")
        hairy.scale = SIMD3(repeating: 0.001)
        hairyEnt.addChild(hairy)
        makeSonos(parent: hairyEnt, name: "hairy.png")
        makeText(parent: hairyEnt, text: "Hairy Woodpecker")
        hairyEnt.generateCollisionShapes(recursive: true)
        arView.installGestures([.all], for: hairyEnt)

        herringEnt = ModelEntity()
        originAnchor.addChild(herringEnt)
        herringEnt.position = [0.5, 0, -1]
        herring = try! Entity.loadModel(named: "herring_gull.usdz")
        herring.position.y = 0.1
        herring.scale = SIMD3(repeating: 0.0008)
        herringEnt.addChild(herring)
        makeSonos(parent: herringEnt, name: "herring.png")
        makeText(parent: herringEnt, text: "American Herring Gull")
        herringEnt.generateCollisionShapes(recursive: true)
        arView.installGestures([.all], for: herringEnt)

        redtailEnt = ModelEntity()
        originAnchor.addChild(redtailEnt)
        redtailEnt.position = [1, 0, -1]
        redtail = try! Entity.loadModel(named: "red-tailed_hawk.usdz")
        redtail.position.z = -0.2
        redtail.position.y = 0.1
        redtail.scale = SIMD3(repeating: 0.01)
        redtailEnt.addChild(redtail)
        makeSonos(parent: redtailEnt, name: "redtail.png")
        makeText(parent: redtailEnt, text: "Red-Tailed Hawk")
        redtailEnt.generateCollisionShapes(recursive: true)
        arView.installGestures([.all], for: redtailEnt)

    }
    
    func makeSonos(parent: Entity, name: String) {
        if #available(iOS 15.0, *) {
            
            var SonoMat = SimpleMaterial()
            SonoMat.color = try! .init(tint: .white, texture: .init(.load(named: name, in: nil)))
            let sono = ModelEntity(mesh: .generatePlane(width: 0.2, depth: 0.1), materials: [SonoMat])
            parent.addChild(sono)
//            sono.scale = SIMD3(repeating: 2)
            sono.orientation = simd_quatf(angle: (3.14 / 2), axis: [1, 0, 0])
            sono.position = [0, -0.06, 0.02]
            

        } else {}
    }
    
    func makeText(parent: Entity, text: String) {
        let textMesh = MeshResource.generateText(text, extrusionDepth: Float(0.005), font: MeshResource.Font.systemFont(ofSize: 0.03))
        let textMaterial = SimpleMaterial(color: .black, isMetallic: false)
        let text = ModelEntity(mesh: textMesh, materials: [textMaterial])
        parent.addChild(text)
        text.position.y = -0.15
        text.position.x -= text.visualBounds(relativeTo: nil).extents.x / 2
    }


    
    func loadAudio() {


        do{
            let bluejay_audio = try AudioFileResource.load(named: "blue jay.mp3",
                                                                in: nil,
                                                         inputMode: .spatial,
                                                   loadingStrategy: .preload,
                                                        shouldLoop: true)
            
            let cardinal_audio = try AudioFileResource.load(named: "cardinal.mp3",
                                                            in: nil,
                                                     inputMode: .spatial,
                                               loadingStrategy: .preload,
                                                    shouldLoop: true)
            
            let hairy_audio = try AudioFileResource.load(named: "hairy.mp3",
                                                            in: nil,
                                                     inputMode: .spatial,
                                               loadingStrategy: .preload,
                                                    shouldLoop: true)
            
            let herring_audio = try AudioFileResource.load(named: "herring gull.mp3",
                                                            in: nil,
                                                     inputMode: .spatial,
                                               loadingStrategy: .preload,
                                                    shouldLoop: true)
            
            let redtail_audio = try AudioFileResource.load(named: "red-tail.mp3",
                                                              in: nil,
                                                       inputMode: .spatial,
                                                 loadingStrategy: .preload,
                                                      shouldLoop: true)
            
            self.bluejayPlayer = bluejay.prepareAudio(bluejay_audio)
            self.cardinalPlayer = cardinal.prepareAudio(cardinal_audio)
            self.hairyPlayer = hairy.prepareAudio(hairy_audio)
            self.herringPlayer = herring.prepareAudio(herring_audio)
            self.redtailPlayer = redtail.prepareAudio(redtail_audio)
            
            self.bluejayPlayer?.gain = -30
            self.cardinalPlayer?.gain = -25
            self.hairyPlayer?.gain = 0
            self.herringPlayer?.gain = -15
            self.redtailPlayer?.gain = -10
            
//            self.bluejayPlayer?.reverbSendLevel = 100
//            self.bluejayPlayer?.
            
            self.bluejayPlayer?.play()
            self.cardinalPlayer?.play()
            self.hairyPlayer?.play()
            self.herringPlayer?.play()
            self.redtailPlayer?.play()
            
        } catch {
            print("Get Error while loading audio file...")
        }
    }

    

    
    func renderLoop() {
        let bDist = pov.position(relativeTo: bluejayEnt)
        let bRay = abs(bDist.x * bDist.z) * 80
        print("b ", bRay)
        bluejayPlayer?.gain = AudioPlaybackController.Decibel(0 - bRay)
        
        let cDist = pov.position(relativeTo: cardinalEnt)
        let cRay = abs(cDist.x * cDist.z) * 80
        print("c ", cRay)
        cardinalPlayer?.gain = AudioPlaybackController.Decibel(0 - cRay)

        let haDist = pov.position(relativeTo: hairyEnt)
        let haRay = abs(haDist.x * haDist.z) * 60
        hairyPlayer?.gain = AudioPlaybackController.Decibel(0 - haRay)

        let heDist = pov.position(relativeTo: herringEnt)
        let heRay = abs(heDist.x * heDist.z) * 80
        herringPlayer?.gain = AudioPlaybackController.Decibel(0 - heRay)

        let rDist = pov.position(relativeTo: redtailEnt)
        let rRay = abs(rDist.x * rDist.z) * 20
        redtailPlayer?.gain = AudioPlaybackController.Decibel(0 - rRay)
        
        

        
    }
    

}
    



