//
//  FreePracticeViewController.swift
//  Learning_Tracker_IOS
//
//  Created by Maxime Richard on 01.03.18.
//  Copyright © 2018 Maxime Richard. All rights reserved.
//

import Foundation
import UIKit


class FreePracticeViewController: UIViewController {
    
    var selectedSubject = "All"
    var subjects = [String]()
    
    @IBOutlet weak var SubjectPicker: UIPickerView!
    @IBAction func StartPracticeButtonTouched(_ sender: Any) {
        print("blabla")
        let myVC = storyboard?.instantiateViewController(withIdentifier: "freePractice") as! FreePracticePageViewController
        myVC.ouaich = "ouaich"
        navigationController?.pushViewController(myVC, animated: true)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        SubjectPicker.delegate = self
        do {
            subjects = try DbTableSubject.getAllSubjects()
        } catch let error {
            print(error)
        }
        var index = subjects.index(of: "")
        if index != nil {
            subjects.remove(at: index!)
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
}

extension FreePracticeViewController: UIPickerViewDelegate, UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return subjects.count
    }
    
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return subjects[row]
    }
    
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        
        selectedSubject = subjects[row]
    }
    
    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
        var label: UILabel
        
        if let view = view as? UILabel {
            label = view
        } else {
            label = UILabel()
        }
        
        label.textAlignment = .center
        label.font = UIFont(name: "Menlo-Regular", size: 17)
        
        label.text = subjects[row]
        
        return label
    }
}
