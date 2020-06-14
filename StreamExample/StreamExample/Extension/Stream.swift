//
//  Stream.swift
//  StreamExample
//
//  Created by Jo JANGHUI on 2020/06/14.
//  Copyright © 2020 Jo JANGHUI. All rights reserved.
//

import Foundation

extension OutputStream {
  func write(data: Data) -> Int {
    return data.withUnsafeBytes {
      write($0.bindMemory(to: UInt8.self).baseAddress!, maxLength: data.count)
    }
  }
}
