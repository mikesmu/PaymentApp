//
//  RefreshTimer.swift
//  RevolutTest
//
//  Created by Michał Smulski on 26/01/2019.
//  Copyright © 2019 Michał Smulski. All rights reserved.
//

import Foundation

class Timer {
    private lazy var timer = DispatchSource.makeTimerSource(flags: .strict, queue: refreshQueue)
    private lazy var refreshQueue = DispatchQueue(label: "ViewController.refresh.data")
    
    init(deadline: DispatchTime, repeatingInterval: Double, handler: @escaping () -> ()) {
        timer.schedule(deadline: deadline, repeating: repeatingInterval)
        timer.setEventHandler { handler() }
    }
    
    func start() {
        timer.resume()
    }
    
    func suspend() {
        timer.suspend()
    }
}
