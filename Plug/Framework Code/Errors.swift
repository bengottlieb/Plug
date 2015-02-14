//
//  Errors.swift
//  Plug
//
//  Created by Ben Gottlieb on 2/13/15.
//  Copyright (c) 2015 Stand Alone, inc. All rights reserved.
//

import Foundation


public extension NSURLResponse {
	public class var PlugHTTPErrorDomain: String { return "PlugHTTPErrorDomain" }
	
	var error: NSError? {
		if let response = self as? NSHTTPURLResponse {
			switch response.statusCode {
			case 200...299: return nil		//no error
			
			default:
				return NSError(domain: NSURLResponse.PlugHTTPErrorDomain, code: response.statusCode, userInfo: ["response": self])
			}
		}
		return nil
	}
}



/*
kCFURLErrorUnknown   = -998,
kCFURLErrorCancelled = -999,
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
