//
//  Helpers.swift
//  Laufpark
//
//  Created by Chris Eidhof on 18.09.17.
//  Copyright © 2017 objc.io. All rights reserved.
//

import Foundation

extension Comparable {
    func clamped(to: ClosedRange<Self>) -> Self {
        if self < to.lowerBound { return to.lowerBound }
        if self > to.upperBound { return to.upperBound }
        return self
    }
}

func lift<A>(_ f: @escaping (A,A) -> Bool) -> (A?,A?) -> Bool {
    return { l, r in
        switch (l,r) {
        case (nil,nil): return true
        case let (x?, y?): return f(x,y)
        default: return false
        }
    }
}

func time(name: StaticString = #function, line: Int = #line, _ f: () -> ()) {
    let startTime = DispatchTime.now()
    f()
    let endTime = DispatchTime.now()
    let diff = (endTime.uptimeNanoseconds - startTime.uptimeNanoseconds) / 1_000_000
    print("\(name) (line \(line)): \(diff)")
}
