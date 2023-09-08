//
//  RRuleSwift.swift
//  RRuleSwift
//
//  Created by Vedant.Fi4m on 08/09/23.
//

import Foundation
import XCGLogger

public class RRuleSwift {
  
  static var logger: XCGLogger = .default
  
  @discardableResult
  public init(logger: XCGLogger) {
    Self.logger = logger
  }
}
