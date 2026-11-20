import Foundation

enum ScreenFlashMode: String {
    case off, firstBeat, accent

    static let storageKey = "metronomeScreenFlashMode"
    static let legacyDefault: Self = UserDefaults.standard.bool(forKey: "metronomeScreenFlash") ? .firstBeat : .off
}

enum BeatAccent: String, Codable, CaseIterable {
    case normal, muted, accent, secondary

    var next: Self {
        switch self {
        case .normal: return .muted
        case .muted: return .accent
        case .accent: return .secondary
        case .secondary: return .normal
        }
    }

    var title: String {
        switch self {
        case .normal: return "Normal"
        case .muted: return "Mute"
        case .accent: return "Accent"
        case .secondary: return "Secondary accent"
        }
    }
}

enum ClickSound: String, Codable, CaseIterable {
    case click = "Click"
    case wood = "Wood"
    case bell = "Bell"

    var title: String { rawValue }
}

/// One BPM pulse is one displayed beat in the selected meter.
struct MetronomeSettings: Codable, Equatable {
    static let tempoRange = 20...300
    static let beatRange = 1...16
    static let denominators = [2, 4, 8, 16]

    var tempo = 120
    var denominator = 4
    var beats: [BeatAccent] = [.accent, .normal, .normal, .normal]
    var sound = ClickSound.click

    var numerator: Int {
        get { beats.count }
        set {
            let count = min(Self.beatRange.upperBound, max(Self.beatRange.lowerBound, newValue))
            if count < beats.count {
                beats.removeLast(beats.count - count)
            } else if count > beats.count {
                beats.append(contentsOf: repeatElement(.normal, count: count - beats.count))
            }
        }
    }

    var tempoTerm: String {
        switch tempo {
        case ..<40: return "Grave"
        case ..<50: return "Largo"
        case ..<60: return "Larghetto"
        case ..<66: return "Adagio"
        case ..<76: return "Adagietto"
        case ..<80: return "Andante"
        case ..<92: return "Andantino"
        case ..<108: return "Andante moderato"
        case ..<112: return "Moderato"
        case ..<120: return "Allegretto"
        case ..<156: return "Allegro"
        case ..<176: return "Vivace"
        case ..<200: return "Presto"
        default: return "Prestissimo"
        }
    }

    init() {}

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        tempo = try container.decode(Int.self, forKey: .tempo)
        denominator = try container.decode(Int.self, forKey: .denominator)
        beats = try container.decode([BeatAccent].self, forKey: .beats)
        sound = try container.decode(ClickSound.self, forKey: .sound)
        guard Self.tempoRange.contains(tempo), Self.denominators.contains(denominator),
              Self.beatRange.contains(beats.count) else {
            throw DecodingError.dataCorrupted(.init(codingPath: decoder.codingPath,
                debugDescription: "Unsupported tempo or time signature"))
        }
    }

    static func load(from defaults: UserDefaults) -> Self {
        if let data = defaults.data(forKey: "metronomeSettings"),
           let settings = try? JSONDecoder().decode(Self.self, from: data) {
            return settings
        }
        var settings = Self()
        if let oldTempo = defaults.object(forKey: "metronomeTempo") as? Int {
            settings.tempo = min(tempoRange.upperBound, max(tempoRange.lowerBound, oldTempo))
        }
        if let oldBeats = defaults.object(forKey: "metronomeBeats") as? Int {
            settings.numerator = oldBeats
        }
        return settings
    }

    func save(to defaults: UserDefaults) {
        defaults.set(try? JSONEncoder().encode(self), forKey: "metronomeSettings")
    }
}
