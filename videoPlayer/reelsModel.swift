//
//  reelsModel.swift
//  videoPlayer
//
//  Created by Chandra Hasan on 02/08/24.
//

import Foundation

struct Reels: Decodable {
    var reels: [reelsArr]
}
struct reelsArr: Decodable {
    var arr: [ReelsDict]
}
struct ReelsDict : Decodable {
    var _id: String
    var video: String
    var thumbnail: String
}
