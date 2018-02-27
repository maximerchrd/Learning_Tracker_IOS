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
        let entry1 = BarChartDataEntry(x: 1.0, y: Double(45))
        let entry2 = BarChartDataEntry(x: 2.0, y: Double(97))
        let entry3 = BarChartDataEntry(x: 3.0, y: Double(4))
        let dataSet = BarChartDataSet(values: [entry1, entry2, entry3], label: "Widgets Type")
        let data = BarChartData(dataSets: [dataSet])
        BarChart.data = data
        BarChart.chartDescription?.text = "Number of Widgets by Type"
        
        //All other additions to this function will go here
        
        //This must stay at end of function
        BarChart.notifyDataSetChanged()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
}
