import SpriteKit
import SwiftUI

struct ContentView: View {
    @State private var scene = GameScene(
        size: CGSize(width: 390, height: 844)
    )

    var body: some View {
        GeometryReader { geometry in
            SpriteView(
                scene: scene,
                options: [.ignoresSiblingOrder, .shouldCullNonVisibleNodes]
            )
            .ignoresSafeArea()
            .onAppear {
                scene.size = geometry.size
                scene.scaleMode = .resizeFill
            }
            .onChange(of: geometry.size) { _, newSize in
                scene.size = newSize
            }
        }
        .background(Color(red: 0.055, green: 0.075, blue: 0.12))
        .preferredColorScheme(.dark)
    }
}
