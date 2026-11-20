struct WatchMeter: Hashable {
    let beats: Int
    let unit: Int

    static let choices = [
        Self(beats: 2, unit: 4), Self(beats: 3, unit: 4), Self(beats: 4, unit: 4), Self(beats: 2, unit: 2),
        Self(beats: 3, unit: 8), Self(beats: 6, unit: 8), Self(beats: 9, unit: 8), Self(beats: 12, unit: 8)
    ]

    var label: String { "\(beats)/\(unit)" }
    var isCompound: Bool { unit == 8 && [6, 9, 12].contains(beats) }

    var accents: [BeatAccent] {
        (0..<beats).map { beat in
            if beat == 0 { return .accent }
            if isCompound && beat.isMultiple(of: 3) { return .secondary }
            if beats == 4 && beat == 2 { return .secondary }
            return .normal
        }
    }

    func applying(to settings: MetronomeSettings) -> MetronomeSettings {
        var updated = settings
        updated.denominator = unit
        updated.beats = accents
        return updated
    }
}
