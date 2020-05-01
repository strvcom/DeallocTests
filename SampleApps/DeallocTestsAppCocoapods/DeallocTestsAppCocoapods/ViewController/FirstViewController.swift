//
//  FirstViewController.swift
//  DeallocTestsAppCocoapods
//
//  Created by Daniel Cech on 01/05/2020.
//  Copyright © 2020 STRV. All rights reserved.
//

import UIKit

protocol FirstViewControllerDelegate: class {
    func firstControllerWillContinue()
}


class FirstViewController: UIViewController {

    weak var flowDelegate: FirstViewControllerDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    @IBAction func continueToNextScreen() {
        flowDelegate?.firstControllerWillContinue()
    }
}
