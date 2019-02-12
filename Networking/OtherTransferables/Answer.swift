class Answer: Encodable {
    var studentDeviceId = ""
    var studentName = ""
    var questionType = ""
    var questionId = ""
    var question = ""
    var timeSpent = -1.0
    var answers = [String]()

    init(studenDeviceId: String = "", studentName: String = "", questionType: String = "", questionId: String = "",
         question: String = "", timeSpent: Double = -1.0, answers: [String] = [String]()) {
        self.studentDeviceId = studenDeviceId
        self.studentName = studentName
        self.questionType = questionType
        self.questionId = questionId
        self.question = question
        self.timeSpent = timeSpent
        self.answers = answers
    }
}