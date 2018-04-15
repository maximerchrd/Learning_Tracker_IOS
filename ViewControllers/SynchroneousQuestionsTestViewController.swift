//
//  SynchroneousQuestionsTestController.swift
//  Learning_Tracker_IOS
//
//  Created by Maxime Richard on 15.04.18.
//  Copyright © 2018 Maxime Richard. All rights reserved.
//

import Foundation
import UIKit

class SynchroneousQuestionsTestViewController: UIPageViewController, UIPageViewControllerDataSource, UIPageViewControllerDelegate {
    var pageControl = UIPageControl()
    var questionsMultipleChoice = [QuestionMultipleChoice]()
    var questionsShortAnswer = [QuestionShortAnswer]()
    var viewControllersArray = [UIViewController]()
    var wifiCommunication = WifiCommunication()
    
    func configurePageControl() {
        pageControl = UIPageControl(frame: CGRect(x: 0,y: UIScreen.main.bounds.maxY - 50,width: UIScreen.main.bounds.width,height: 50))
        self.pageControl.numberOfPages = orderedViewControllers.count
        self.pageControl.currentPage = 0
        self.pageControl.tintColor = UIColor.black
        self.pageControl.pageIndicatorTintColor = UIColor.lightGray
        self.pageControl.currentPageIndicatorTintColor = UIColor.black
        self.view.addSubview(pageControl)
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard let viewControllerIndex = orderedViewControllers.index(of: viewController) else {
            return nil
        }
        
        let previousIndex = viewControllerIndex - 1
        
        // User is on the first view controller and swiped left to loop to
        // the last view controller.
        guard previousIndex >= 0 else {
            //return orderedViewControllers.last
            // Uncommment the line below, remove the line above if you don't want the page control to loop.
            return nil
        }
        
        guard orderedViewControllers.count > previousIndex else {
            return nil
        }
        
        return orderedViewControllers[previousIndex]
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let viewControllerIndex = orderedViewControllers.index(of: viewController) else {
            return nil
        }
        
        let nextIndex = viewControllerIndex + 1
        let orderedViewControllersCount = orderedViewControllers.count
        
        // User is on the last view controller and swiped right to loop to
        // the first view controller.
        guard orderedViewControllersCount != nextIndex else {
            //return orderedViewControllers.first
            // Uncommment the line below, remove the line above if you don't want the page control to loop.
            return nil
        }
        
        guard orderedViewControllersCount > nextIndex else {
            return nil
        }
        
        return orderedViewControllers[nextIndex]
    }
    
    func newVc(viewController: String) -> UIViewController {
        return UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: viewController)
    }
    lazy var orderedViewControllers: [UIViewController] = {
        return viewControllersArray
    }()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if (viewControllersArray.count < 1) {
            for questionMC in questionsMultipleChoice {
                let questionVC = storyboard?.instantiateViewController(withIdentifier: "QuestionMultipleChoiceViewController") as! QuestionMultipleChoiceViewController
                questionVC.questionMultipleChoice = questionMC
                questionVC.isSyncTest = true
                questionVC.wifiCommunication = wifiCommunication
                viewControllersArray.append(questionVC)
            }
            for questionSA in questionsShortAnswer {
                let questionVC = storyboard?.instantiateViewController(withIdentifier: "QuestionShortAnswerViewController") as! QuestionShortAnswerViewController
                questionVC.questionShortAnswer = questionSA
                questionVC.isSyncTest = true
                questionVC.wifiCommunication = wifiCommunication
                viewControllersArray.append(questionVC)
            }
        }
        // Do any additional setup after loading the view, typically from a nib.
        self.dataSource = self
        // This sets up the first view that will show up on our page control
        if let firstViewController = orderedViewControllers.first {
            setViewControllers([firstViewController],
                               direction: .forward,
                               animated: true,
                               completion: nil)
        }
        self.delegate = self
        self.automaticallyAdjustsScrollViewInsets = false;
        configurePageControl()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        viewControllersArray[0].viewDidAppear(animated)
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        let pageContentViewController = pageViewController.viewControllers![0]
        self.pageControl.currentPage = orderedViewControllers.index(of: pageContentViewController)!
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
}
