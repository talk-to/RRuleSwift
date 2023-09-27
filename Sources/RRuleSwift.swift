//
//  RRuleSwift.swift
//  RRuleSwift
//
//  Created by Vedant.Fi4m on 08/09/23.
//

import Foundation
import XCGLogger

public protocol RRuleSwiftFirebaseNonFatalErrorRecorder {
  func recordUnexpectedDateFormat(errorInfo: [String: Any])
}

public class RRuleSwift {
  
  private(set) static var logger: XCGLogger = .default
  private(set) static var nonFatalErrorRecorder: RRuleSwiftFirebaseNonFatalErrorRecorder?
  
  @discardableResult
  public init(logger: XCGLogger, nonFatalErrorRecorder: RRuleSwiftFirebaseNonFatalErrorRecorder) {
    Self.logger = logger
    Self.nonFatalErrorRecorder = nonFatalErrorRecorder
  }
}
