import Foundation

let localeCodes = ["en", "ko", "zh-Hans", "ja", "es", "fr", "pt-BR"]
typealias Values = [String]

func values(_ en: String, _ ko: String, _ zh: String, _ ja: String, _ es: String, _ fr: String, _ pt: String) -> Values {
    [en, ko, zh, ja, es, fr, pt]
}

var rows: [(String, Values)] = [
    ("app.title", values("Last Beacon", "라스트 비콘", "最后信标", "ラスト・ビーコン", "Última Baliza", "Dernière Balise", "Último Farol")),
    ("home.subtitle", values("Hold the final signal.", "마지막 신호를 지켜라.", "守住最后的信号。", "最後の信号を守れ。", "Defiende la última señal.", "Défendez le dernier signal.", "Defenda o último sinal.")),
    ("home.start", values("Start Mission", "임무 시작", "开始任务", "ミッション開始", "Iniciar misión", "Lancer la mission", "Iniciar missão")),
    ("home.endless", values("Endless", "무한 모드", "无尽模式", "エンドレス", "Infinito", "Sans fin", "Infinito")),
    ("home.settings", values("Settings", "설정", "设置", "設定", "Ajustes", "Réglages", "Ajustes")),
    ("common.back", values("Back", "뒤로", "返回", "戻る", "Atrás", "Retour", "Voltar")),
    ("common.locked", values("Locked", "잠김", "未解锁", "ロック中", "Bloqueado", "Verrouillé", "Bloqueado")),
    ("common.continue", values("Continue", "계속", "继续", "続ける", "Continuar", "Continuer", "Continuar")),
    ("common.retry", values("Retry", "다시 하기", "重试", "再挑戦", "Reintentar", "Réessayer", "Tentar de novo")),
    ("common.home", values("Home", "홈", "主页", "ホーム", "Inicio", "Accueil", "Início")),
    ("missions.title", values("Select Mission", "임무 선택", "选择任务", "ミッション選択", "Elegir misión", "Choisir une mission", "Escolher missão")),
    ("missions.sector", values("Sector %lld", "구역 %lld", "区域 %lld", "セクター%lld", "Sector %lld", "Secteur %lld", "Setor %lld")),
    ("missions.mission", values("Mission %lld", "임무 %lld", "任务 %lld", "ミッション%lld", "Misión %lld", "Mission %lld", "Missão %lld")),
    ("game.wave", values("Wave %lld / %lld", "웨이브 %lld / %lld", "波次 %lld / %lld", "ウェーブ %lld / %lld", "Oleada %lld / %lld", "Vague %lld / %lld", "Onda %lld / %lld")),
    ("game.energy", values("Energy %lld", "에너지 %lld", "能量 %lld", "エネルギー %lld", "Energía %lld", "Énergie %lld", "Energia %lld")),
    ("game.beacon", values("Beacon %lld", "비콘 %lld", "信标 %lld", "ビーコン %lld", "Baliza %lld", "Balise %lld", "Farol %lld")),
    ("game.build", values("Build", "건설", "建造", "建設", "Construir", "Construire", "Construir")),
    ("game.upgrade", values("Upgrade", "강화", "升级", "強化", "Mejorar", "Améliorer", "Melhorar")),
    ("game.sell", values("Sell", "판매", "出售", "売却", "Vender", "Vendre", "Vender")),
    ("game.startWave", values("Start Wave", "웨이브 시작", "开始波次", "ウェーブ開始", "Iniciar oleada", "Lancer la vague", "Iniciar onda")),
    ("game.chooseUpgrade", values("Choose an Upgrade", "업그레이드 선택", "选择升级", "アップグレード選択", "Elige una mejora", "Choisissez une amélioration", "Escolha uma melhoria")),
    ("results.victory", values("Signal Secured", "신호 방어 성공", "信号已守住", "信号を防衛", "Señal protegida", "Signal protégé", "Sinal protegido")),
    ("results.defeat", values("Beacon Lost", "비콘 파괴", "信标已失守", "ビーコン喪失", "Baliza perdida", "Balise perdue", "Farol perdido")),
    ("results.salvage", values("Salvage %lld", "회수품 %lld", "回收物 %lld", "サルベージ %lld", "Restos %lld", "Récupération %lld", "Sucata %lld")),
    ("results.stars", values("Stars %lld", "별 %lld", "星星 %lld", "スター %lld", "Estrellas %lld", "Étoiles %lld", "Estrelas %lld")),
    ("settings.title", values("Settings", "설정", "设置", "設定", "Ajustes", "Réglages", "Ajustes")),
    ("settings.music", values("Music", "음악", "音乐", "音楽", "Música", "Musique", "Música")),
    ("settings.effects", values("Sound Effects", "효과음", "音效", "効果音", "Efectos de sonido", "Effets sonores", "Efeitos sonoros")),
    ("settings.haptics", values("Haptics", "진동", "触感反馈", "触覚フィードバック", "Respuesta háptica", "Retour haptique", "Resposta tátil")),
    ("settings.reduceMotion", values("Reduce Motion", "동작 줄이기", "减少动态效果", "視差効果を減らす", "Reducir movimiento", "Réduire les animations", "Reduzir movimento")),
    ("settings.privacy", values("Privacy Options", "개인정보 보호 옵션", "隐私选项", "プライバシー設定", "Opciones de privacidad", "Options de confidentialité", "Opções de privacidade")),
    ("settings.tutorial", values("Replay Tutorial", "튜토리얼 다시 보기", "重玩教程", "チュートリアル再生", "Repetir tutorial", "Rejouer le tutoriel", "Repetir tutorial")),
    ("ad.revive", values("Watch to restore 40%", "광고를 보고 40% 복구", "观看广告恢复40%", "広告を見て40%回復", "Mira un anuncio para recuperar 40%", "Regarder pour restaurer 40 %", "Assista para restaurar 40%")),
    ("ad.unavailable", values("Ad unavailable. Continue without waiting.", "광고를 불러올 수 없습니다. 기다리지 않고 계속합니다.", "广告暂不可用，将直接继续。", "広告を利用できません。そのまま続行します。", "Anuncio no disponible. Continúa sin esperar.", "Publicité indisponible. Continuez sans attendre.", "Anúncio indisponível. Continue sem esperar.")),
    ("tutorial.welcome", values("Protect the beacon through eight waves.", "8개의 웨이브 동안 비콘을 지키세요.", "守护信标，抵御八波攻击。", "8ウェーブの間ビーコンを守ろう。", "Protege la baliza durante ocho oleadas.", "Protégez la balise pendant huit vagues.", "Proteja o farol por oito ondas.")),
    ("tutorial.buildPulse", values("Build a Pulse Cannon in the highlighted socket.", "강조된 슬롯에 펄스포를 건설하세요.", "在高亮槽位建造脉冲炮。", "光るスロットにパルス砲を建設しよう。", "Construye un cañón de pulso en el espacio resaltado.", "Construisez un canon à impulsion dans l’emplacement indiqué.", "Construa um canhão de pulso no espaço destacado.")),
    ("tutorial.startWave", values("Start the wave when ready.", "준비되면 웨이브를 시작하세요.", "准备好后开始波次。", "準備ができたらウェーブを開始。", "Inicia la oleada cuando estés listo.", "Lancez la vague quand vous êtes prêt.", "Inicie a onda quando estiver pronto.")),
    ("tutorial.upgradePulse", values("Upgrade the Pulse Cannon.", "펄스포를 강화하세요.", "升级脉冲炮。", "パルス砲を強化しよう。", "Mejora el cañón de pulso.", "Améliorez le canon à impulsion.", "Melhore o canhão de pulso.")),
    ("tutorial.complete", values("Signal stable. The sector awaits.", "신호가 안정되었습니다. 다음 구역이 기다립니다.", "信号已稳定，区域等待探索。", "信号は安定した。次のセクターへ。", "Señal estable. El sector te espera.", "Signal stable. Le secteur vous attend.", "Sinal estável. O setor aguarda.")),
    ("tower.pulse.name", values("Pulse Cannon", "펄스포", "脉冲炮", "パルス砲", "Cañón de pulso", "Canon à impulsion", "Canhão de pulso")),
    ("tower.laser.name", values("Laser Lance", "레이저포", "激光枪", "レーザーランス", "Lanza láser", "Lance laser", "Lança laser")),
    ("tower.gravity.name", values("Gravity Well", "중력장", "重力井", "重力井戸", "Pozo gravitatorio", "Puits gravitationnel", "Poço gravitacional"))
]

let upgradeNames: [(String, Values, String)] = [
    ("pulse-capacitors", values("Pulse Capacitors", "펄스 축전기", "脉冲电容", "パルス蓄電器", "Condensadores de pulso", "Condensateurs à impulsion", "Capacitores de pulso"), "pulse"),
    ("burst-sync", values("Burst Sync", "연사 동기화", "连发同步", "バースト同期", "Ráfaga sincronizada", "Rafale synchronisée", "Rajada sincronizada"), "pulse"),
    ("pulse-overclock", values("Pulse Overclock", "펄스 오버클록", "脉冲超频", "パルス過給", "Sobrecarga de pulso", "Surcadence à impulsion", "Sobrecarga de pulso"), "pulse"),
    ("cascade-rounds", values("Cascade Rounds", "연쇄 탄환", "级联炮弹", "カスケード弾", "Proyectiles en cascada", "Salves en cascade", "Disparos em cascata"), "pulse"),
    ("laser-focus", values("Laser Focus", "레이저 집속", "激光聚焦", "レーザー集束", "Enfoque láser", "Focalisation laser", "Foco laser"), "laser"),
    ("armor-piercer", values("Armor Piercer", "장갑 관통", "装甲穿透", "装甲貫通", "Perforaarmaduras", "Perce-blindage", "Perfura-blindagem"), "laser"),
    ("heat-sink", values("Heat Sink", "방열판", "散热器", "ヒートシンク", "Disipador térmico", "Dissipateur thermique", "Dissipador térmico"), "laser"),
    ("beam-split", values("Split Beam", "분할 광선", "分裂光束", "分裂ビーム", "Rayo dividido", "Rayon scindé", "Feixe dividido"), "laser"),
    ("gravity-depth", values("Gravity Depth", "중력 심화", "重力加深", "重力深化", "Gravedad profunda", "Gravité profonde", "Gravidade profunda"), "gravity"),
    ("wide-field", values("Wide Field", "광역 중력장", "广域力场", "広域フィールド", "Campo amplio", "Champ étendu", "Campo amplo"), "gravity"),
    ("time-dilation", values("Time Dilation", "시간 지연", "时间膨胀", "時間遅延", "Dilatación temporal", "Dilatation temporelle", "Dilatação temporal"), "gravity"),
    ("singularity", values("Singularity", "특이점", "奇点", "特異点", "Singularidad", "Singularité", "Singularidade"), "gravity"),
    ("repair-nanites", values("Repair Nanites", "수리 나노봇", "修复纳米机", "修復ナノマシン", "Nanitas reparadoras", "Nanites de réparation", "Nanitas de reparo"), "beacon"),
    ("shield-pulse", values("Shield Pulse", "보호막 파동", "护盾脉冲", "シールドパルス", "Pulso de escudo", "Impulsion de bouclier", "Pulso de escudo"), "beacon"),
    ("emergency-power", values("Emergency Power", "비상 전력", "应急电力", "緊急電力", "Energía de emergencia", "Énergie de secours", "Energia de emergência"), "beacon"),
    ("hardened-core", values("Hardened Core", "강화 코어", "强化核心", "強化コア", "Núcleo reforzado", "Cœur renforcé", "Núcleo reforçado"), "beacon"),
    ("salvage-protocol", values("Salvage Protocol", "회수 프로토콜", "回收协议", "回収プロトコル", "Protocolo de rescate", "Protocole de récupération", "Protocolo de sucata"), "economy"),
    ("efficient-build", values("Efficient Build", "효율 건설", "高效建造", "効率建設", "Construcción eficiente", "Construction efficace", "Construção eficiente"), "economy"),
    ("recycling", values("Recycling", "재활용", "资源循环", "リサイクル", "Reciclaje", "Recyclage", "Reciclagem"), "economy"),
    ("wave-bonus", values("Wave Bonus", "웨이브 보너스", "波次奖励", "ウェーブボーナス", "Bono de oleada", "Bonus de vague", "Bônus de onda"), "economy"),
    ("crossfire", values("Crossfire", "교차 사격", "交叉火力", "十字砲火", "Fuego cruzado", "Tir croisé", "Fogo cruzado"), "synergy"),
    ("resonance", values("Resonance", "공명", "共振", "共鳴", "Resonancia", "Résonance", "Ressonância"), "synergy"),
    ("triad", values("Triad", "삼중 연계", "三联协同", "トライアド", "Tríada", "Triade", "Tríade"), "synergy"),
    ("last-stand", values("Last Stand", "최후의 저항", "最后防线", "最後の抵抗", "Última resistencia", "Dernier rempart", "Última resistência"), "synergy")
]

let descriptions: [String: Values] = [
    "pulse": values("Improves Pulse Cannon combat performance.", "펄스포의 전투 성능을 강화합니다.", "强化脉冲炮的战斗性能。", "パルス砲の戦闘性能を強化する。", "Mejora el rendimiento del cañón de pulso.", "Améliore les performances du canon à impulsion.", "Melhora o desempenho do canhão de pulso."),
    "laser": values("Improves Laser Lance power and efficiency.", "레이저포의 위력과 효율을 강화합니다.", "提升激光枪的威力与效率。", "レーザーランスの威力と効率を高める。", "Mejora la potencia y eficiencia de la lanza láser.", "Améliore la puissance et l’efficacité de la lance laser.", "Melhora a potência e a eficiência da lança laser."),
    "gravity": values("Strengthens Gravity Well control effects.", "중력장의 제어 효과를 강화합니다.", "强化重力井的控制效果。", "重力井戸の制御効果を強化する。", "Refuerza los efectos del pozo gravitatorio.", "Renforce les effets du puits gravitationnel.", "Fortalece os efeitos do poço gravitacional."),
    "beacon": values("Improves beacon survival and recovery.", "비콘의 생존력과 복구 능력을 강화합니다.", "提升信标的生存与修复能力。", "ビーコンの耐久力と回復力を高める。", "Mejora la resistencia y recuperación de la baliza.", "Améliore la survie et la réparation de la balise.", "Melhora a resistência e a recuperação do farol."),
    "economy": values("Provides more energy or salvage efficiency.", "에너지 또는 회수 효율을 높입니다.", "提高能量或回收效率。", "エネルギーや回収効率を高める。", "Aumenta la eficiencia de energía o restos.", "Augmente l’efficacité énergétique ou de récupération.", "Aumenta a eficiência de energia ou sucata."),
    "synergy": values("Rewards combining different tower systems.", "서로 다른 포탑을 조합하면 보상을 얻습니다.", "组合不同炮塔可获得加成。", "異なるタワーの組み合わせを強化する。", "Premia la combinación de torres distintas.", "Récompense la combinaison de tours différentes.", "Recompensa a combinação de torres diferentes.")
]

for (id, names, category) in upgradeNames {
    rows.append(("upgrade.\(id).name", names))
    rows.append(("upgrade.\(id).description", descriptions[category]!))
}

var strings: [String: Any] = [:]
for (key, translatedValues) in rows {
    var localizations: [String: Any] = [:]
    for (index, locale) in localeCodes.enumerated() {
        localizations[locale] = [
            "stringUnit": [
                "state": "translated",
                "value": translatedValues[index]
            ]
        ]
    }
    strings[key] = ["localizations": localizations]
}

let root: [String: Any] = [
    "sourceLanguage": "en",
    "version": "1.0",
    "strings": strings
]
let output = URL(fileURLWithPath: "LastBeacon/Resources/Localizable.xcstrings")
let data = try JSONSerialization.data(withJSONObject: root, options: [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes])
try data.write(to: output, options: .atomic)
