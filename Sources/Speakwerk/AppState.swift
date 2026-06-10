enum AppState: Equatable {
    case idle
    case recording
    case transcribing
    case downloadingModel(Double)
    case error(String)
}
