import CoreGraphics
import SpriteKit

enum BattlefieldLayout {
    static func laneX(_ lane: Int, in size: CGSize) -> CGFloat {
        size.width * (0.2 + (CGFloat(lane) * 0.3))
    }

    static func socketPoint(_ socket: Int, in size: CGSize) -> CGPoint {
        let lane = socket % 3
        let row = socket / 3
        return CGPoint(
            x: laneX(lane, in: size),
            y: size.height * (row == 0 ? 0.38 : 0.68)
        )
    }

    static func enemyPoint(_ enemy: Enemy, in size: CGSize) -> CGPoint {
        CGPoint(
            x: laneX(enemy.lane, in: size),
            y: size.height * (0.9 - (0.76 * enemy.progress))
        )
    }
}

@MainActor
enum BattlefieldRenderer {
    static func addBackground(to scene: SKScene) {
        for index in 0..<28 {
            let star = SKShapeNode(circleOfRadius: index.isMultiple(of: 5) ? 1.5 : 0.8)
            star.fillColor = .white.withAlphaComponent(index.isMultiple(of: 3) ? 0.55 : 0.25)
            star.strokeColor = .clear
            star.position = CGPoint(
                x: CGFloat((index * 71) % 101) / 100 * scene.size.width,
                y: CGFloat((index * 43) % 97) / 100 * scene.size.height
            )
            scene.addChild(star)
        }

        for lane in 0..<3 {
            let path = CGMutablePath()
            let x = BattlefieldLayout.laneX(lane, in: scene.size)
            path.move(to: CGPoint(x: x, y: scene.size.height * 0.12))
            path.addLine(to: CGPoint(x: x, y: scene.size.height * 0.94))
            let line = SKShapeNode(path: path)
            line.strokeColor = SKColor.cyan.withAlphaComponent(0.14)
            line.lineWidth = 2
            scene.addChild(line)
        }
    }

    static func addBeacon(snapshot: GameSnapshot, to scene: SKScene) {
        let beacon = SKShapeNode(circleOfRadius: 26)
        beacon.position = CGPoint(x: scene.size.width / 2, y: scene.size.height * 0.08)
        beacon.fillColor = SKColor.cyan.withAlphaComponent(0.28)
        beacon.strokeColor = .cyan
        beacon.lineWidth = 3
        beacon.glowWidth = 10
        scene.addChild(beacon)
    }

    static func addSockets(snapshot: GameSnapshot, to scene: SKScene) {
        for socket in 0..<6 {
            let ring = SKShapeNode(circleOfRadius: 23)
            ring.position = BattlefieldLayout.socketPoint(socket, in: scene.size)
            ring.fillColor = SKColor.black.withAlphaComponent(0.35)
            ring.strokeColor = SKColor.cyan.withAlphaComponent(0.3)
            ring.lineWidth = 2
            scene.addChild(ring)
        }

        for tower in snapshot.towers {
            let node: SKShapeNode
            switch tower.kind {
            case .pulse:
                node = SKShapeNode(circleOfRadius: 13)
                node.fillColor = .cyan
            case .laser:
                let path = CGMutablePath()
                path.move(to: CGPoint(x: 0, y: 16))
                path.addLine(to: CGPoint(x: -14, y: -12))
                path.addLine(to: CGPoint(x: 14, y: -12))
                path.closeSubpath()
                node = SKShapeNode(path: path)
                node.fillColor = .systemYellow
            case .gravity:
                node = SKShapeNode(circleOfRadius: 14)
                node.fillColor = .clear
                node.lineWidth = 5
            }
            node.position = BattlefieldLayout.socketPoint(tower.socket, in: scene.size)
            node.strokeColor = tower.kind == .gravity ? .systemPurple : .white
            node.glowWidth = 6
            scene.addChild(node)

            let level = SKLabelNode(text: "\(tower.level)")
            level.fontName = "AvenirNext-Bold"
            level.fontSize = 10
            level.fontColor = .white
            level.verticalAlignmentMode = .center
            level.position = CGPoint(x: 16, y: -18)
            node.addChild(level)
        }
    }

    static func addEnemies(snapshot: GameSnapshot, to scene: SKScene) {
        for enemy in snapshot.enemies {
            let radius: CGFloat = enemy.kind == .sectorBoss ? 21 : 13
            let node = SKShapeNode(rectOf: CGSize(width: radius * 1.8, height: radius * 1.4), cornerRadius: 5)
            node.position = BattlefieldLayout.enemyPoint(enemy, in: scene.size)
            node.fillColor = color(for: enemy.kind)
            node.strokeColor = .white.withAlphaComponent(0.8)
            node.lineWidth = enemy.kind == .armoredFrigate ? 4 : 2
            node.glowWidth = enemy.kind == .sectorBoss ? 8 : 3
            node.zRotation = enemy.kind == .drone ? .pi / 4 : 0
            scene.addChild(node)

            if enemy.shield > 0 {
                let shield = SKShapeNode(circleOfRadius: radius + 7)
                shield.strokeColor = .cyan.withAlphaComponent(0.75)
                shield.fillColor = .clear
                shield.lineWidth = 2
                node.addChild(shield)
            }

            let healthFraction = max(0, enemy.health / enemy.maximumHealth)
            let health = SKShapeNode(rectOf: CGSize(width: 28 * healthFraction, height: 3))
            health.fillColor = .systemPink
            health.strokeColor = .clear
            health.position = CGPoint(x: -14 + (14 * healthFraction), y: radius + 8)
            node.addChild(health)
        }
    }

    private static func color(for kind: EnemyKind) -> SKColor {
        switch kind {
        case .drone: .systemPink
        case .swarm: .systemOrange
        case .armoredFrigate: .systemGray
        case .shieldVessel: .systemBlue
        case .splitter: .systemPurple
        case .sectorBoss: .red
        }
    }
}
