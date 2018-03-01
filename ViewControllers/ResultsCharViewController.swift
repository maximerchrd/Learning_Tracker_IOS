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
    

    @IBOutlet weak var BarChart: BarChartView!

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        barChartUpdate()
    }
    
    func barChartUpdate () {
        do {
            var evalForObjectives = try DbTableLearningObjective.getResultsPerObjective(subject: "All")
            var objectives = evalForObjectives[0]
            var results = evalForObjectives[1]
            var entries = [BarChartDataEntry]()
            for i in 0..<results.count {
                let entry = BarChartDataEntry(x: Double(i + 1), y: Double(results[i]) ?? 0.0)
                entries.append(entry)
            }
            let dataSet = BarChartDataSet(values: entries, label: "Evaluation for each learning objective")
            let data = BarChartData(dataSets: [dataSet])
            BarChart.data = data
            
            let xAxis = BarChart.xAxis
            xAxis.granularity = 1.0
            //xAxis.setPosition(XAxis.XAxisPosition.TOP_INSIDE);
            //xAxis.setDrawGridLines(false);
            xAxis.valueFormatter = IndexAxisValueFormatter(values: objectives)
            xAxis.labelPosition = XAxis.LabelPosition.bottom
            xAxis.labelCount = objectives.count
            
            let yAxis = BarChart.leftAxis
            yAxis.axisMaximum = 100.0
            yAxis.axisMinimum = 0.0
            let yAxisright = BarChart.rightAxis
            yAxisright.axisMaximum = 100.0
            yAxisright.axisMinimum = 0.0

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
