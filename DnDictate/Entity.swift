//
//  Entity.swift
//  DnDictate
//
//  Created by Sam Robinson on 3/25/25.
//

struct Entity: Identifiable, Decodable, Encodable {
    let id: Int
    let name: String
    let description: String // Add any other fields you need
}
