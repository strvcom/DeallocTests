//
//  SecondViewController.swift
//  DeallocTestsApp
//
//  Created by Daniel Cech on 01/05/2020.
//  Copyright © 2020 STRV. All rights reserved.
//

import UIKit

protocol SecondViewControllerDelegate: AnyObject {
    func secondControllerWillContinue()
}

class SecondViewController: UIViewController {
    
    weak var flowDelegate: SecondViewControllerDelegate?
    var someClosure: ((Int) -> ())!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // strong self in this closure creates a retain cycle; make it weak and it will work
        someClosure = { number in self.view(number) }
//         someClosure = { [weak self] number in self?.view(number) }
        
        someClosure(5)
        
        // Do any additional setup after loading the view.
    }
        
    func view(_ number: Int) {
        // some method
    }
    
    @IBAction func continueToNextScreen() {
        flowDelegate?.secondControllerWillContinue()
    }
}
