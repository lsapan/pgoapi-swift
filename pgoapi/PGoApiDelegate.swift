//
//  PGoApiDelegate.swift
//  pgomap
//
//  Created by Luke Sapan on 7/20/16.
//  Copyright © 2016 Coadstal. All rights reserved.
//

import Foundation
import ProtocolBuffers


protocol PGoApiDelegate {
    func didReceiveApiResponse(intent: ApiIntent, response: ApiResponse)
    func didReceiveApiError(intent: ApiIntent, statusCode: Int?)
}
