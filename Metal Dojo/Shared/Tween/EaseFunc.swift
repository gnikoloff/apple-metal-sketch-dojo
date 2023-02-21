//
//  EaseFunc.swift
//  MetalDojo
//
//  Created by Georgi Nikoloff on 29.12.22.
//

// swiftlint:disable identifier_name
// swiftlint:disable cyclomatic_complexity
// swiftlint:disable function_body_length

import QuartzCore

enum Easing {
  case linear,
       quadIn,
       quadOut,
       quadInOut,

       cubicIn,
       cubicOut,
       cubicInOut,
       
       quartIn,
       quartOut,
       quartInOut,

       quintIn,
       quintOut,
       quintInOut,

       sineIn,
       sineOut,
       sineInOut,
       
       expIn,
       expOut,
       expInOut,
       
       circIn,
       circOut,
       circInOut,
       
       elasticIn,
       elasticOut,
       elasticInOut,
       
       backIn,
       backOut,
       backInOut
}

extension Easing {
  func apply(time: CFAbsoluteTime) -> CFAbsoluteTime {
    switch self {
      case .linear:
        return time
        
      case .quadIn:
        return time * time
        
      case .quadOut:
        return -time * (time - 2)
        
      case .quadInOut:
        if time < 0.5 {
          return 2 * time * time
        }
        return (-2 * time * time) + (4 * time) - 1
        
      case .cubicIn:
        return time * time * time
        
      case .cubicOut:
        let p = time - 1
        return p * p * p + 1
        
      case .cubicInOut:
        if time < 0.5 {
          return 4 * time * time * time
        }
        let f = 2 * time - 2
        return 0.5 * f * f * f + 1
        
      case .quartIn:
        return time * time * time * time
        
      case .quartOut:
        let f = time - 1
        return f * f * f * (1 - time) + 1
        
      case .quartInOut:
        if time < 1 / 2 {
          return 8 * time * time * time * time
        } else {
          let f = time - 1
          return -8 * f * f * f * f + 1
        }
        
      case .quintIn:
        return time * time * time * time * time
        
      case .quintOut:
        let f = time - 1
        return f * f * f * f * f + 1
        
      case .quintInOut:
        if time < 1 / 2 {
          return 16 * time * time * time * time * time
        } else {
          let f = 2 * time - 2
          let g = f * f * f * f * f
          return 1 / 2 * g + 1
        }
        
      case .sineIn:
        return sin((time - 1) * Double.pi / 2) + 1

      case .sineOut:
        return sin(time * Double.pi / 2)
        
      case .sineInOut:
        return 0.5 * ((1 - cos(time * Double.pi)))
        
      case .circIn:
        return 1 - sqrt(1 - time * time)
        
      case .circOut:
        return sqrt((2 - time) * time)
        
      case .circInOut:
        if time < 1 / 2 {
          let h = 1 - sqrt(1 - 4 * time * time)
          return 1 / 2 * h
        } else {
          let f = 2 * time - 1
          let g = -(2 * time - 3) * f
          let h = sqrt(g)
          return 0.5 * (h + 1)
        }
      
      case .expIn:
        return time == 0 ? time : pow(2, 10 * (time - 1))
      
      case .expOut:
        return time == 1 ? time : 1 - pow(2, -10 * time)
        
      case .expInOut:
        if time == 0 || time == 1 {
          return time
        }
        if time < 0.5 {
          return 0.5 * pow(2, 20 * time - 10)
        } else {
          let h = pow(2, -20 * time + 10)
          return -0.5 * h + 1
        }
        
      case .elasticIn:
        return sin(13 * Double.pi / 2 * time) * pow(2, 10 * (time - 1))
        
      case .elasticOut:
        let f = sin(-13 * Double.pi / 2 * (time + 1))
        let g = pow(2, -10 * time)
        return f * g + 1
        
      case .elasticInOut:
        if time < 0.5 {
          let f = sin((13 * Double.pi / 2) * 2 * time)
          let g = pow(2, 10 * ((2 * time) - 1))
          return 0.5 * f * g
        } else {
          let h = (2 * time - 1) + 1
          let f = sin(-13 * Double.pi / 2 * h)
          let g = pow(2, -10 * (2 * time - 1))
          return 0.5 * (f * g + 2)
        }
        
      case .backIn:
        return time * time * time - time * sin(time * Double.pi)
        
      case .backOut:
        let c = 1.70158
        let f = c + 1
        let g = (time - 1) * (time - 1) * (time - 1)
        let h = (time - 1) * (time - 1)
        let i = f * g
        return 1 + i + c * h
        
      case .backInOut:
        if time < 1 / 2 {
          let f = 2 * time
          let g = f * f * f - f * sin(f * Double.pi)
          return 1 / 2 * g
        } else {
          let f = 1 - (2 * time - 1)
          let g = sin(f * Double.pi)
          let h = f * f * f - f * g
          let i = 1 - h
          return 1 / 2 * i + 1 / 2
        }
    }
  }
}
