//
//  ResultsCharViewController.swift
//  Learning_Tracker_IOS
//
//  Created by Maxime Richard on 27.02.18.
//  Copyright © 2018 Maxime Richard. All rights reserved.
//

import Foundation
import UIKit
import Charts

class ResultsChartViewController: UIViewController {
    

    @IBOutlet weak var BarChart: HorizontalBarChartView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        barChartUpdate(subject: "All")
    }
    
    public func barChartUpdate (subject: String) {
        do {
            var evalForObjectives = try DbTableLearningObjective.getResultsPerObjective(subject: subject)
            var objectives = evalForObjectives[0]
            var results = evalForObjectives[1]
            let indexOfEmpty = objectives.index(of: "")
            if indexOfEmpty != nil {
                results.remove(at: indexOfEmpty!)
                objectives.remove(at: indexOfEmpty!)
            }
            objectives.insert("", at: 0)
            results.insert("0.0", at: 0)
            
            var entries = [BarChartDataEntry]()
            for i in 0..<results.count {
                let entry = BarChartDataEntry(x: Double(i) - 0.5, yValues: [Double(results[i]) ?? 0.0])
                entries.append(entry)
            }
            let dataSet = BarChartDataSet(values: entries, label: NSLocalizedString("Evaluation for each learning objective", comment: "chart label"))
            dataSet.drawValuesEnabled = false
            let data = BarChartData(dataSets: [dataSet])
            
            BarChart.data = data
            
            let xAxis = BarChart.xAxis
            xAxis.granularity = 0.5
            //xAxis.setDrawGridLines(false);
            xAxis.valueFormatter = IndexAxisValueFormatter(values: objectives)
            xAxis.labelPosition = XAxis.LabelPosition.bottomInside
            xAxis.labelCount = results.count * 2
            xAxis.axisMinimum = 0.0
            xAxis.drawGridLinesEnabled = false
            
            
            
            let yAxis = BarChart.leftAxis
            yAxis.axisMaximum = 100.0
            yAxis.axisMinimum = 0.0
            yAxis.labelCount = 10
            let yAxisright = BarChart.rightAxis
            yAxisright.axisMaximum = 100.0
            yAxisright.axisMinimum = 0.0
            yAxisright.labelCount = 10

            BarChart.notifyDataSetChanged()
        } catch let error {
            print(error)
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
}
