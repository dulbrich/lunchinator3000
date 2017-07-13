//
//  CallFactory.swift
//  Retrolux
//
//  Created by Christopher Bryan Henderson on 10/8/16.
//  Copyright © 2016 Bryan. All rights reserved.
//

import Foundation

public protocol CallFactory {
    func makeCall<T>(capture: @escaping () -> RequestCapturedState, perform: @escaping CallPerformFunction<T>, cancel: @escaping () -> Void) -> Call<T>
}
