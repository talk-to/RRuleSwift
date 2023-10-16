//
//  Iterators.swift
//  RRuleSwift
//
//  Created by Xin Hong on 16/3/29.
//  Copyright © 2016年 Teambition. All rights reserved.
//

import Foundation
import JavaScriptCore

@objc protocol JSDelegate: JSExport {
  func log(_ message: String)
}
@objc class SwiftJSDelegate: NSObject, JSDelegate {
  func log(_ message: String) {
    RRuleSwift.logger.debug(message)
  }
}

public struct Iterator {
  public static let endlessRecurrenceCount = 500
  internal static let rruleContext: JSContext? = {
    guard let rrulejs = JavaScriptBridge.rrulejs() else {
      return nil
    }
    let context = JSContext()
    context?.setObject(SwiftJSDelegate(), forKeyedSubscript: "swiftJSDelegate" as NSCopying & NSObjectProtocol)
    context?.exceptionHandler = { context, exception in
      let description = String(describing: exception)
      RRuleSwift.logger.debug("RRule.Swift encountered error \(description)")
      print("[RRuleSwift] rrule.js error: \(description)")
    }
    let _ = context?.evaluateScript(rrulejs)
    return context
  }()
}

@objc
public extension RecurrenceRule {
  @objc
  func allOccurrences(endless endlessRecurrenceCount: Int = Iterator.endlessRecurrenceCount) -> [Date] {
    guard let _ = JavaScriptBridge.rrulejs() else {
      return []
    }
    
    let ruleJSONString = toJSONString(endless: endlessRecurrenceCount)
    let _ = Iterator.rruleContext?.evaluateScript("var rule = new RRule({ \(ruleJSONString) })")
    guard let allOccurrences = Iterator.rruleContext?.evaluateScript("rule.all()").toArray() as? [Date] else {
      return []
    }
    
    var occurrences = allOccurrences
    if let rdates = rdate?.dates {
      occurrences.append(contentsOf: rdates)
    }
    
    if let exdates = exdate?.dates, let component = exdate?.component {
      for occurrence in occurrences {
        for exdate in exdates {
          if calendar.isDate(occurrence, equalTo: exdate, toGranularity: component) {
            let index = occurrences.firstIndex(of: occurrence)!
            occurrences.remove(at: index)
            break
          }
        }
      }
    }
    
    return occurrences.sorted { $0.isBeforeOrSame(with: $1) }
  }
  
  @objc
  func occurrences(between date: Date, and otherDate: Date, inclusive: Bool, endless endlessRecurrenceCount: Int = Iterator.endlessRecurrenceCount) -> [Date] {
    guard let _ = JavaScriptBridge.rrulejs() else {
      return []
    }
    
    let beginDate = date.isBeforeOrSame(with: otherDate) ? date : otherDate
    let untilDate = otherDate.isAfterOrSame(with: date) ? otherDate : date
    let beginDateJSON = beginDate.toJSDateFormat
    let untilDateJSON = untilDate.toJSDateFormat
    
    let ruleJSONString = toJSONString(endless: endlessRecurrenceCount)
    RRuleSwift.logger.debug("RRule.Swift starting expansion for \(ruleJSONString)")
    let _ = Iterator.rruleContext?.evaluateScript("var rule = new RRule({ \(ruleJSONString) })")
    RRuleSwift.logger.debug("RRule.Swift starting expansion between \(beginDateJSON) and \(untilDateJSON)")
    
    if [beginDateJSON, untilDateJSON, ruleJSONString].contains(where: { $0.contains("AMZ") || $0.contains("PMZ") }) {
      let userInfo = [
        "beginDateJSON": beginDateJSON,
        "untilDateJSON": untilDateJSON,
        "ruleJSONString": ruleJSONString,
        "toRRuleString": toRRuleString()
      ]
      RRuleSwift.nonFatalErrorRecorder?.recordUnexpectedDateFormat(errorInfo: userInfo)
      return [startDate]
    }
    
    
    guard let betweenOccurrences = Iterator.rruleContext?.evaluateScript("rule.between(new Date('\(beginDateJSON)'), new Date('\(untilDateJSON)'), \(inclusive))").toArray() as? [Date] else {
      RRuleSwift.logger.debug("RRule.Swift did not evaluateScript rule.between")
      return []
    }
    
    var occurrences = betweenOccurrences
    if let rdates = rdate?.dates {
      occurrences.append(contentsOf: rdates)
    }
    
    if let exdates = exdate?.dates, let component = exdate?.component {
      for occurrence in occurrences {
        for exdate in exdates {
          if calendar.isDate(occurrence, equalTo: exdate, toGranularity: component) {
            let index = occurrences.firstIndex(of: occurrence)!
            occurrences.remove(at: index)
            break
          }
        }
      }
    }
    
    RRuleSwift.logger.debug("RRule.Swift ending expansion with \(occurrences.count) occurrences")
    return occurrences.sorted { $0.isBeforeOrSame(with: $1) }
  }
}

extension Date {
  private static let calendar: Calendar = {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(secondsFromGMT: 0)!
    return calendar
  }()
  private var year: String { String(format: "%02d", Self.calendar.component(.year, from: self)) }
  private var month: String { String(format: "%02d", Self.calendar.component(.month, from: self)) }
  private var day: String { String(format: "%02d", Self.calendar.component(.day, from: self)) }
  private var hour: String { String(format: "%02d", Self.calendar.component(.hour, from: self)) }
  private var minute: String { String(format: "%02d", Self.calendar.component(.minute, from: self)) }
  private var second: String { String(format: "%02d", Self.calendar.component(.second, from: self)) }
  
  var toJSDateFormat: String {
    "\(year)-\(month)-\(day)T\(hour):\(minute):\(second)Z"
  }
}
