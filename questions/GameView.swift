class GameView : Decodable {
    var gameType = -1
    var endScore = 30
    var theme = 0
    var team = 0

    static let manualSending = 0
    static let orderedAutomaticSending = 1
    static let randomAutomaticSending = 2
    static let qrCodeGame = 3


    init(gameType: Int = -1, endScore: Int = 30, theme: Int = 0, team: Int = 0) {
        self.gameType = gameType
        self.endScore = endScore
        self.theme = theme
        self.team = team
    }
}