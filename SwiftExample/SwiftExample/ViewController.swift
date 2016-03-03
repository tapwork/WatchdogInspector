//
//  ViewController.swift
//  SwiftExample
//
//  Created by Christian Menschel on 03/03/16.
//  Copyright © 2016 TAPWORK. All rights reserved.
//

import UIKit

class ViewController: UITableViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        self.edgesForExtendedLayout = .None
    }


    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 100
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("CELL", forIndexPath: indexPath)
        cell.textLabel?.text = "Row \(indexPath.row)"
        NSThread.sleepForTimeInterval(0.03)

        return cell
    }
}

