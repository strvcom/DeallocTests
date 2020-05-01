//
//  SecondViewController.swift
//  DeallocTestsAppCocoapods
//
//  Created by Daniel Cech on 01/05/2020.
//  Copyright © 2020 STRV. All rights reserved.
//

import UIKit

protocol SecondViewControllerDelegate: class {
    func secondControllerWillContinue()
}

class SecondViewController: UIViewController {
    
    var flowDelegate: SecondViewControllerDelegate?
    var a: ((Int) -> ())!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        a = { number in self.view(number) }
        a(5)
        
        // Do any additional setup after loading the view.
    }
        
    func view(_ number: Int) {
        
    }
    
    @IBAction func continueToNextScreen() {
        flowDelegate?.secondControllerWillContinue()
    }
}
