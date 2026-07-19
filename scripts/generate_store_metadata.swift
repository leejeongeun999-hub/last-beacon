#!/usr/bin/env swift
import Foundation

struct StoreLocale {
    let code: String
    let name: String
    let subtitle: String
    let promotional: String
    let description: String
    let keywords: String
}

let locales = [
    StoreLocale(
        code: "en-US",
        name: "Last Beacon: Orbit Defense",
        subtitle: "Tactical sci-fi tower defense",
        promotional: "Hold three orbital lanes, combine specialized towers, and keep humanity's last beacon online.",
        description: """
        The final beacon is surrounded. Build a compact defense grid and survive eight escalating waves in focused 5–10 minute missions.

        • Defend three orbital lanes from six enemy classes
        • Combine Pulse, Laser, and Gravity towers
        • Choose run-changing upgrades between waves
        • Conquer 12 handcrafted missions across three sectors
        • Play in English, Korean, Simplified Chinese, Japanese, Spanish, French, or Brazilian Portuguese

        Last Beacon is free to play and supported by ads. Optional rewarded ads can restore the beacon once during a defeated run.
        """,
        keywords: "tower defense,strategy,space,sci-fi,tactical,offline,beacon,orbit,defense game"
    ),
    StoreLocale(
        code: "ko",
        name: "라스트 비콘: 궤도 방어",
        subtitle: "5분 전략 SF 타워 디펜스",
        promotional: "세 개의 궤도 항로를 지키고 특화 타워를 조합해 인류의 마지막 비콘을 사수하세요.",
        description: """
        마지막 비콘이 포위되었습니다. 치밀한 방어망을 구축하고 5~10분의 집중된 임무에서 점점 강해지는 8개 웨이브를 막아내세요.

        • 세 개의 궤도 항로와 여섯 종류의 적
        • 펄스, 레이저, 중력 타워 조합
        • 웨이브 사이에서 선택하는 강화 효과
        • 세 구역에 걸친 12개의 설계된 임무
        • 한국어 포함 7개 언어 지원

        라스트 비콘은 광고로 운영되는 무료 게임입니다. 선택형 보상 광고를 보면 패배한 전투에서 비콘을 한 번 복구할 수 있습니다.
        """,
        keywords: "타워디펜스,전략게임,우주,SF,전술,오프라인,비콘,궤도,방어게임"
    ),
    StoreLocale(
        code: "zh-Hans",
        name: "最后信标：轨道防御",
        subtitle: "快节奏科幻塔防策略",
        promotional: "守住三条轨道航线，组合特色防御塔，让人类最后的信标继续闪耀。",
        description: """
        最后的信标已被包围。建立紧凑的防线，在每局5到10分钟的任务中抵御八波不断增强的敌人。

        • 防守三条轨道航线，对抗六类敌人
        • 组合脉冲、激光和重力防御塔
        • 在波次之间选择强化效果
        • 挑战三个星区的12个精心设计任务
        • 支持简体中文等七种语言

        《最后信标》可免费下载并由广告支持。你可以自愿观看奖励广告，在失败的战斗中恢复一次信标。
        """,
        keywords: "塔防,策略,太空,科幻,战术,离线,信标,轨道,防御游戏"
    ),
    StoreLocale(
        code: "ja",
        name: "ラストビーコン：軌道防衛",
        subtitle: "短時間SFタワーディフェンス",
        promotional: "3本の軌道レーンを守り、特化タワーを組み合わせて人類最後のビーコンを防衛しよう。",
        description: """
        最後のビーコンが包囲された。コンパクトな防衛網を築き、5～10分のミッションで激しさを増す8ウェーブを耐え抜こう。

        • 3本の軌道レーンと6種類の敵
        • パルス、レーザー、グラビティタワー
        • ウェーブ間で選ぶ強化アップグレード
        • 3セクターに広がる12の設計ミッション
        • 日本語を含む7言語に対応

        ラストビーコンは広告付きの無料ゲームです。任意のリワード広告で、敗北した戦闘中にビーコンを1回復旧できます。
        """,
        keywords: "タワーディフェンス,戦略,宇宙,SF,戦術,オフライン,ビーコン,軌道,防衛"
    ),
    StoreLocale(
        code: "es-ES",
        name: "Última Baliza: Defensa",
        subtitle: "Defensa táctica espacial",
        promotional: "Protege tres rutas orbitales, combina torres especializadas y mantén activa la última baliza.",
        description: """
        La última baliza está rodeada. Construye una defensa compacta y supera ocho oleadas crecientes en misiones de 5 a 10 minutos.

        • Defiende tres rutas orbitales de seis clases enemigas
        • Combina torres de Pulso, Láser y Gravedad
        • Elige mejoras decisivas entre oleadas
        • Completa 12 misiones diseñadas en tres sectores
        • Disponible en siete idiomas

        Última Baliza es gratis y contiene anuncios. Un anuncio recompensado opcional puede restaurar la baliza una vez tras una derrota.
        """,
        keywords: "torres,estrategia,espacio,ciencia ficción,táctica,offline,órbita,defensa,juego"
    ),
    StoreLocale(
        code: "fr-FR",
        name: "Dernier Signal : Défense",
        subtitle: "Défense tactique spatiale",
        promotional: "Défendez trois voies orbitales, combinez vos tours et maintenez le dernier signal de l'humanité.",
        description: """
        Le dernier signal est encerclé. Construisez une défense compacte et survivez à huit vagues croissantes lors de missions de 5 à 10 minutes.

        • Défendez trois voies orbitales contre six types d'ennemis
        • Combinez les tours Pulse, Laser et Gravité
        • Choisissez des améliorations entre les vagues
        • Terminez 12 missions dans trois secteurs
        • Jouez dans sept langues

        Dernier Signal est gratuit et financé par la publicité. Une publicité récompensée facultative peut restaurer le signal une fois après une défaite.
        """,
        keywords: "tower defense,stratégie,espace,science-fiction,tactique,hors ligne,orbite,défense"
    ),
    StoreLocale(
        code: "pt-BR",
        name: "Último Farol: Defesa",
        subtitle: "Defesa tática espacial",
        promotional: "Proteja três rotas orbitais, combine torres especiais e mantenha o último farol da humanidade ativo.",
        description: """
        O último farol está cercado. Monte uma defesa compacta e sobreviva a oito ondas crescentes em missões de 5 a 10 minutos.

        • Defenda três rotas orbitais de seis tipos de inimigo
        • Combine torres de Pulso, Laser e Gravidade
        • Escolha melhorias entre as ondas
        • Vença 12 missões em três setores
        • Jogue em sete idiomas

        Último Farol é grátis e contém anúncios. Um anúncio recompensado opcional pode restaurar o farol uma vez após uma derrota.
        """,
        keywords: "defesa de torres,estratégia,espaço,ficção científica,tática,offline,órbita,jogo"
    )
]

let projectRoot = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let metadataRoot = projectRoot.appendingPathComponent("fastlane/metadata", isDirectory: true)
let supportURL = "https://leejeongeun999-hub.github.io/last-beacon/support.html"
let privacyURL = "https://leejeongeun999-hub.github.io/last-beacon/privacy.html"

for locale in locales {
    let directory = metadataRoot.appendingPathComponent(locale.code, isDirectory: true)
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    let values = [
        "name.txt": locale.name,
        "subtitle.txt": locale.subtitle,
        "promotional_text.txt": locale.promotional,
        "description.txt": locale.description,
        "keywords.txt": locale.keywords,
        "support_url.txt": supportURL,
        "privacy_url.txt": privacyURL
    ]
    for (filename, value) in values {
        try Data((value + "\n").utf8).write(to: directory.appendingPathComponent(filename), options: .atomic)
    }
}
