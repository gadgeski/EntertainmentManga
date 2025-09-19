//
//  JSON+Decoder.swift
//  EntertainmentManga
//
//  Created by Dev Tech on 2025/09/19.
//

// Support/JSON+Decoder.swift

import Foundation

extension JSONDecoder {
    static var iso8601: JSONDecoder {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }
}
