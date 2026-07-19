import SpriteKit

@MainActor
final class BattlefieldScene: SKScene {
    private let onFrame: @MainActor (TimeInterval) -> GameSnapshot?
    private var lastUpdateTime: TimeInterval?
    private var lastSnapshot: GameSnapshot?

    init(onFrame: @escaping @MainActor (TimeInterval) -> GameSnapshot?) {
        self.onFrame = onFrame
        super.init(size: CGSize(width: 390, height: 700))
        scaleMode = .resizeFill
        backgroundColor = .clear
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) is unavailable") }

    override func update(_ currentTime: TimeInterval) {
        let delta = lastUpdateTime.map { currentTime - $0 } ?? 0
        lastUpdateTime = currentTime
        if let snapshot = onFrame(delta) {
            lastSnapshot = snapshot
            render(snapshot)
        }
    }

    override func didChangeSize(_ oldSize: CGSize) {
        guard let lastSnapshot else { return }
        render(lastSnapshot)
    }

    private func render(_ snapshot: GameSnapshot) {
        removeAllChildren()
        BattlefieldRenderer.addBackground(to: self)
        BattlefieldRenderer.addBeacon(snapshot: snapshot, to: self)
        BattlefieldRenderer.addSockets(snapshot: snapshot, to: self)
        BattlefieldRenderer.addEnemies(snapshot: snapshot, to: self)
    }
}

