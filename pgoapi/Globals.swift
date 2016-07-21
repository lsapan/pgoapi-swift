//
//  Globals.swift
//  pgomap
//
//  Created by Luke Sapan on 7/20/16.
//  Copyright © 2016 Coadstal. All rights reserved.
//

import Foundation

struct Endpoint {
    static let LoginInfo = "https://sso.pokemon.com/sso/login?service=https%3A%2F%2Fsso.pokemon.com%2Fsso%2Foauth2.0%2FcallbackAuthorize"
    static let LoginTicket = "https://sso.pokemon.com/sso/login?service=https%3A%2F%2Fsso.pokemon.com%2Fsso%2Foauth2.0%2FcallbackAuthorize"
    static let LoginOAuth = "https://sso.pokemon.com/sso/oauth2.0/accessToken"
    static let Rpc = "https://pgorelease.nianticlabs.com/plfe/rpc"
}

struct Api {
    static var endpoint = Endpoint.Rpc
    static let id: UInt64 = 8145806132888207460
    static let SettingsHash = "05daf51635c82611d1aac95c0b051d3ec088a930"
}

enum ApiIntent {
    case Login
    case GetMapObjects
}
