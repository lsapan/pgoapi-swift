//
//  PGoApiDelegate.swift
//  pgomap
//
//  Created by Luke Sapan on 7/20/16.
//  Copyright © 2016 Coadstal. All rights reserved.
//

import Foundation


public protocol PGoApiDelegate {
    func didReceiveApiResponse(intent: PGoApiIntent, response: PGoApiResponse)
    func didReceiveApiError(intent: PGoApiIntent, statusCode: Int?)
    func didReceiveApiException(intent: PGoApiIntent, exception: PGoApiExceptions)
}

public enum PGoApiExceptions {
    case NoApiMethodsCalled
    case Banned
    case NotLoggedIn
    case AuthTokenExpired
    case NoAuth
    case DelayRequired
    case InvalidRequest
    case SessionInvalidated
    case Unknown
}