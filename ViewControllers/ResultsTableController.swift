//
//  ResultsTableController.swift
//  Learning_Tracker_IOS
//
//  Created by Maxime Richard on 12.04.18.
//  Copyright © 2018 Maxime Richard. All rights reserved.
//

import Foundation
import UIKit

class ResultsTableViewCell: UITableViewCell {
    @IBOutlet weak var QuestionLabel: UILabel!
    @IBOutlet weak var AnswerLabel: UILabel!
    @IBOutlet weak var EvaluationLabel: UILabel!
}


class ResultsTableController: UITableViewController {
    var results = [[String]]()
    var questions = [String]()
    var answers = [String]()
    var evaluations = [Double]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        do {
            results = try DbTableIndividualQuestionForResult.getResultsForSubject(subject: "All")
        } catch let error {
            print(error)
        }
        
        
        
        for result in results {
            questions.append(result[0])
            answers.append(result[1])
            evaluations.append(Double(result[2]) ?? -1.0)
        }
    }
    
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if (section == 1) {
            return evaluations.count
        } else {
            return 1
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ResultCell", for: indexPath) as! ResultsTableViewCell
        
        if (indexPath.section == 1) {
            let question = questions[indexPath.row]
            cell.QuestionLabel?.text = question
            let answer = answers[indexPath.row]
            cell.AnswerLabel?.text = answer
            let evaluation = evaluations[indexPath.row]
            cell.EvaluationLabel?.text = String(evaluation)
        } else {
            cell.QuestionLabel?.text = "Question"
            cell.QuestionLabel?.font = UIFont.boldSystemFont(ofSize: 16.0)
            cell.AnswerLabel?.text = "Your Answer"
            cell.AnswerLabel?.font = UIFont.boldSystemFont(ofSize: 16.0)
            cell.EvaluationLabel?.text = "Evaluation"
            cell.EvaluationLabel?.font = UIFont.boldSystemFont(ofSize: 16.0)
        }
        return cell
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
}
