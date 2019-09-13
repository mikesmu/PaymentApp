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
