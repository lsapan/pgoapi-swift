//
//  PGoApiDelegate.swift
//  pgomap
//
//  Created by Luke Sapan on 7/20/16.
//  Copyright © 2016 Coadstal. All rights reserved.
//

import Foundation


public protocol PGoApiDelegate {
    func didReceiveApiResponse(_ intent: PGoApiIntent, response: PGoApiResponse)
    func didReceiveApiError(_ intent: PGoApiIntent, statusCode: Int?)
    func didReceiveApiException(_ intent: PGoApiIntent, exception: PGoApiExceptions)
}

public enum PGoApiExceptions {
    case noApiMethodsCalled
    case banned
    case notLoggedIn
    case authTokenExpired
    case noAuth
    case delayRequired
    case invalidRequest
    case sessionInvalidated
    case unknown
    case captchaRequired
}
