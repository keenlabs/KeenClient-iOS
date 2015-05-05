//
//  SecondViewController.swift
//  KeenSwiftClientExample
//
//  Created by Claire Young on 5/4/15.
//  Copyright (c) 2015 Keen.IO. All rights reserved.
//

import UIKit

class SecondViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    override func viewWillAppear(animated: Bool) {
        
        let theEvent = ["view_name": "second view Swift", "action": "going to"];
        
        KeenClient.sharedClient().addEvent(theEvent, toEventCollection: "tab_views", error: nil);
    }
    
    override func viewWillDisappear(animated : Bool) {
        
        super.viewWillDisappear(animated);
        let theEvent = ["view_name" : "second view Swift", "action" : "leaving from"];
        KeenClient.sharedClient().addEvent(theEvent, toEventCollection: "tab_views", error: nil);
    }

}

