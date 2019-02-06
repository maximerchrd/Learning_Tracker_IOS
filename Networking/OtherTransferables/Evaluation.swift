class Evaluation: Decodable {
    var evaluationType = 0
    var identifier = ""
    var name = ""
    var evaluation = 0.0
    var evalUpdate = false
    var testIdentifier = ""
    var testName = ""

    static let questionEvaluation = 0
    static let objectiveEvaluation = 1
}