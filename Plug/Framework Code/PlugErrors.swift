//
//  Errors.swift
//  Plug
//
//  Created by Ben Gottlieb on 2/13/15.
//  Copyright (c) 2015 Stand Alone, inc. All rights reserved.
//

import Foundation


public extension URLResponse {
	enum StatusCode: Int, Error { case badRequest = 400, unauthorized = 401, paymentRequired = 402, forbidden = 403, fileNotFound = 404, methodNotAllowed = 405, notAcceptable = 406, proxyAuthenticationRequired = 407, requestTimedOut = 408, conflict = 409, gone = 410, lengthRequired = 411, preconditionFailed = 412, payloadTooLarge = 413, uriTooLong = 414, unsupportedMediaType = 415, rangeNotSatisfiable = 416, expectationFailed = 417, imATeapot = 418, misdirectedRequest = 421, unprocessableEntity = 422, locked = 423, failedDependency = 424, upgradeRequired = 426, preconditionRequired = 428, tooManyRequests = 429, requestHeaderFieldsTooLarge = 431, unavailableForLegalReasons = 451
		
		case internalServerError = 500, notImplemented = 501, badGateway = 502, serviceUnavailable = 503, gatewayTimeout = 504, httpVersionNotSupported = 505, variantAlsoNegotiates = 506, insufficientStorage = 507, loopDetected = 508, notExtended = 510, networkAuthenticationRequired = 511
	}
	
	var error: Error? {
		if let response = self as? HTTPURLResponse, let error = StatusCode(rawValue: response.statusCode) { return error }
		
		return nil
	}
}

extension URLResponse.StatusCode: LocalizedError {
	public var errorDescription: String? {
		switch self {
		case .badRequest: return "bad request"
		case .unauthorized: return "unauthorized"
		case .paymentRequired: return "payment required"
		case .forbidden: return "forbidden"
		case .fileNotFound: return "file not found"
		case .methodNotAllowed: return "method not allowed"
		case .notAcceptable: return "not acceptable"
		case .proxyAuthenticationRequired: return "proxy authentication required"
		case .requestTimedOut: return "request timed out"
		case .conflict: return "conflict"
		case .gone: return "gone"
		case .lengthRequired: return "length required"
		case .preconditionFailed: return "precondition failed"
		case .payloadTooLarge: return "payload too large"
		case .uriTooLong: return "URI too long"
		case .unsupportedMediaType: return "unsupported media type"
		case .rangeNotSatisfiable: return "range not satisfiable"
		case .expectationFailed: return "expectation failed"
		case .imATeapot: return "I'm a teapot"
		case .misdirectedRequest: return "misdirected request"
		case .unprocessableEntity: return "unprocessable entity"
		case .locked: return "locked"
		case .failedDependency: return "failed dependency"
		case .upgradeRequired: return "upgrade required"
		case .preconditionRequired: return "pecondition required"
		case .tooManyRequests: return "too many requests"
		case .requestHeaderFieldsTooLarge: return "request header fields too large"
		case .unavailableForLegalReasons: return "unavailable for legal reasons"
			
		case .internalServerError: return "internal server error"
		case .notImplemented: return "not implemented"
		case .badGateway: return "bad gatewau"
		case .serviceUnavailable: return "service unavailable"
		case .gatewayTimeout: return "gateway timeout"
		case .httpVersionNotSupported: return "HTTP version not supported"
		case .variantAlsoNegotiates: return "variant also negotiates"
		case .insufficientStorage: return "insufficient storage"
		case .loopDetected: return "loop detected"
		case .notExtended: return "not extended"
		case .networkAuthenticationRequired: return "network authentication required"
		}
	}
}

public enum JSONErrors: Int { case unableToFindJSONContainer, unexpectedJSONDictionary, unexpectedJSONArray }
public extension Error {
	public static var PlugJSONErrorDomain: String { return "PlugJSONErrorDomain" }
	
	public var isCancelledError: Bool {
		let err = self as NSError
		return err.domain == NSURLErrorDomain && err.code == Int(CFNetworkErrors.cfurlErrorCancelled.rawValue)
	}
	
	public var isTimeoutError: Bool {
		let err = self as NSError
		if err.domain != NSURLErrorDomain { return false }
		if err.code == Int(CFNetworkErrors.cfurlErrorTimedOut.rawValue) { return true }
		if err.code == Int(CFNetworkErrors.cfurlErrorCannotConnectToHost.rawValue) { return true }
		return false
	}
}

/*
kCFURLErrorUnknown   = -998,
kcfurlErrorCancelled = -999,
kCFURLErrorBadURL    = -1000,
kCFURLErrorTimedOut  = -1001,
kCFURLErrorUnsupportedURL = -1002,
kCFURLErrorCannotFindHost = -1003,
kCFURLErrorCannotConnectToHost    = -1004,
kCFURLErrorNetworkConnectionLost  = -1005,
kCFURLErrorDNSLookupFailed        = -1006,
kCFURLErrorHTTPTooManyRedirects   = -1007,
kCFURLErrorResourceUnavailable    = -1008,
kCFURLErrorNotConnectedToInternet = -1009,
kCFURLErrorRedirectToNonExistentLocation = -1010,
kCFURLErrorBadServerResponse             = -1011,
kCFURLErrorUserCancelledAuthentication   = -1012,
kCFURLErrorUserAuthenticationRequired    = -1013,
kCFURLErrorZeroByteResource        = -1014,
kCFURLErrorCannotDecodeRawData     = -1015,
kCFURLErrorCannotDecodeContentData = -1016,
kCFURLErrorCannotParseResponse     = -1017,
kCFURLErrorInternationalRoamingOff = -1018,
kCFURLErrorCallIsActive               = -1019,
kCFURLErrorDataNotAllowed             = -1020,
kCFURLErrorRequestBodyStreamExhausted = -1021,
kCFURLErrorFileDoesNotExist           = -1100,
kCFURLErrorFileIsDirectory            = -1101,
kCFURLErrorNoPermissionsToReadFile    = -1102,
kCFURLErrorDataLengthExceedsMaximum   = -1103,


enum CFNetworkErrors : Int32 {
case CFHostErrorHostNotFound
case CFHostErrorUnknown
case CFSOCKSErrorUnknownClientVersion
case CFSOCKSErrorUnsupportedServerVersion
case CFSOCKS4ErrorRequestFailed
case CFSOCKS4ErrorIdentdFailed
case CFSOCKS4ErrorIdConflict
case CFSOCKS4ErrorUnknownStatusCode
case CFSOCKS5ErrorBadState
case CFSOCKS5ErrorBadResponseAddr
case CFSOCKS5ErrorBadCredentials
case CFSOCKS5ErrorUnsupportedNegotiationMethod
case CFSOCKS5ErrorNoAcceptableMethod
case CFFTPErrorUnexpectedStatusCode
case CFErrorHTTPAuthenticationTypeUnsupported
case CFErrorHTTPBadCredentials
case CFErrorHTTPConnectionLost
case CFErrorHTTPParseFailure
case CFErrorHTTPRedirectionLoopDetected
case CFErrorHTTPBadURL
case CFErrorHTTPProxyConnectionFailure
case CFErrorHTTPBadProxyCredentials
case CFErrorPACFileError
case CFErrorPACFileAuth
case CFErrorHTTPSProxyConnectionFailure
case CFStreamErrorHTTPSProxyFailureUnexpectedResponseToCONNECTMethod
case CFURLErrorBackgroundSessionInUseByAnotherProcess
case CFURLErrorBackgroundSessionWasDisconnected
case CFURLErrorUnknown
case CFURLErrorCancelled
case CFURLErrorBadURL
case CFURLErrorTimedOut
case CFURLErrorUnsupportedURL
case CFURLErrorCannotFindHost
case CFURLErrorCannotConnectToHost
case CFURLErrorNetworkConnectionLost
case CFURLErrorDNSLookupFailed
case CFURLErrorHTTPTooManyRedirects
case CFURLErrorResourceUnavailable
case CFURLErrorNotConnectedToInternet
case CFURLErrorRedirectToNonExistentLocation
case CFURLErrorBadServerResponse
case CFURLErrorUserCancelledAuthentication
case CFURLErrorUserAuthenticationRequired
case CFURLErrorZeroByteResource
case CFURLErrorCannotDecodeRawData
case CFURLErrorCannotDecodeContentData
case CFURLErrorCannotParseResponse
case CFURLErrorInternationalRoamingOff
case CFURLErrorCallIsActive
case CFURLErrorDataNotAllowed
case CFURLErrorRequestBodyStreamExhausted
case CFURLErrorFileDoesNotExist
case CFURLErrorFileIsDirectory
case CFURLErrorNoPermissionsToReadFile
case CFURLErrorDataLengthExceedsMaximum
case CFURLErrorSecureConnectionFailed
case CFURLErrorServerCertificateHasBadDate
case CFURLErrorServerCertificateUntrusted
case CFURLErrorServerCertificateHasUnknownRoot
case CFURLErrorServerCertificateNotYetValid
case CFURLErrorClientCertificateRejected
case CFURLErrorClientCertificateRequired
case CFURLErrorCannotLoadFromNetwork
case CFURLErrorCannotCreateFile
case CFURLErrorCannotOpenFile
case CFURLErrorCannotCloseFile
case CFURLErrorCannotWriteToFile
case CFURLErrorCannotRemoveFile
case CFURLErrorCannotMoveFile
case CFURLErrorDownloadDecodingFailedMidStream
case CFURLErrorDownloadDecodingFailedToComplete
case CFHTTPCookieCannotParseCookieFile
case CFNetServiceErrorUnknown
case CFNetServiceErrorCollision
case CFNetServiceErrorNotFound
case CFNetServiceErrorInProgress
case CFNetServiceErrorBadArgument
case CFNetServiceErrorCancel
case CFNetServiceErrorInvalid
case CFNetServiceErrorTimeout
case CFNetServiceErrorDNSServiceFailure
}

*/
