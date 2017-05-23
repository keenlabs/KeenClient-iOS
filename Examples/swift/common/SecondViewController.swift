//
//  SecondViewController.swift
//  KeenClientExampleSwift
//
//  Created by Claire Young on 5/4/15.
//  Copyright (c) 2015 Keen.IO. All rights reserved.
//

import UIKit
import KeenClient

class SecondViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    override func viewWillAppear(_ animated: Bool) {
        
        super.viewWillAppear(animated);
        let theEvent = ["view_name": "second view Swift", "action": "going to"];
        do {
            try KeenClient.shared().addEvent(theEvent, toEventCollection: "tab_views")
        } catch _ {
        };
    }
    
    override func viewWillDisappear(_ animated : Bool) {
        
        super.viewWillDisappear(animated);
        let theEvent = ["view_name" : "second view Swift", "action" : "leaving from"];
        do {
            try KeenClient.shared().addEvent(theEvent, toEventCollection: "tab_views")
        } catch _ {
        };
    }

}

