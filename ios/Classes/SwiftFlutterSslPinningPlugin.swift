import Flutter
import UIKit
import CryptoSwift
import Alamofire

public class SwiftFlutterSslPinningPlugin: NSObject, FlutterPlugin {
    
    let manager = Alamofire.SessionManager.default
    var flutterResult: FlutterResult?
    var fingerprints: Array<String>?
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "flutter_ssl_pinning", binaryMessenger: registrar.messenger())
        let instance = SwiftFlutterSslPinningPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        self.flutterResult = result
        switch (call.method) {
        case "validating":
            if let _args = call.arguments as? Dictionary<String, AnyObject> {
                self.validating(call: call, args: _args)
            } else {
                result(FlutterError(code: "INVALID_ARGUMENTS", message: nil, details: nil))
            }
            break
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    public func sendResponse(result: AnyObject) {
        if let res = self.flutterResult {
            res(result)
        }
    }
    
    public func validating(call: FlutterMethodCall, args: Dictionary<String, AnyObject>){
        
        guard let urlString = args["url"] as? String,
            let headers = args["headers"] as? Dictionary<String, String>,
            let fingerprints = args["fingerprints"] as? Array<String>,
            let type = args["type"] as? String,
            type == "sha1" || type == "sha256"
            else {
                self.sendResponse(result: FlutterError(code: "INVALID_PARAMS", message: nil, details: nil))
                return
        }
        
        self.fingerprints = fingerprints
        
        var timeout = 60
        if let timeoutArg = args["timeout"] as? Int {
            timeout = timeoutArg
        }
        
        Alamofire.request(urlString, parameters: headers).validate().responseJSON() { response in
            switch response.result {
            case .success:
                break
            case .failure(let error):
                self.sendResponse(result: FlutterError(code: "INVALID_URL", message: error.localizedDescription, details: nil))
                break
            }
        }
        
        manager.session.configuration.timeoutIntervalForRequest = TimeInterval(timeout)
        
        manager.delegate.sessionDidReceiveChallenge = { session, challenge in
            
            guard let serverTrust = challenge.protectionSpace.serverTrust, let certificate = SecTrustGetCertificateAtIndex(serverTrust, 0) else {
                self.sendResponse(result: FlutterError(code: "INVALID_CERTIFICATE", message: nil, details: nil))
                return (.cancelAuthenticationChallenge, nil)
            }
            
            // Set SSL policies for domain name check
            let policies: [SecPolicy] = [SecPolicyCreateSSL(true, (challenge.protectionSpace.host as CFString))]
            SecTrustSetPolicies(serverTrust, policies as CFTypeRef)
            
            // Evaluate server certificate
            var result: SecTrustResultType = .invalid
            SecTrustEvaluate(serverTrust, &result)
            let isServerTrusted: Bool = (result == .unspecified || result == .proceed)
            
            let serverCertData = SecCertificateCopyData(certificate) as Data
            var serverCertSha = serverCertData.sha256().toHexString()
            
            if type == "sha1" {
                serverCertSha = serverCertData.sha1().toHexString()
            }
            
            var isSecure = false
            if var fp = self.fingerprints {
                fp = fp.compactMap { (val) -> String? in
                    val.replacingOccurrences(of: " ", with: "")
                }
                
                isSecure = fp.contains(where: { (value) -> Bool in
                    value.caseInsensitiveCompare(serverCertSha) == .orderedSame
                })
            }
            
            if isServerTrusted && isSecure {
                self.sendResponse(result: 1 as AnyObject)
            } else {
                self.sendResponse(result: FlutterError(code: "CONNECTION_NOT_SECURED", message: nil, details: nil))
            }
            
            return (.cancelAuthenticationChallenge, nil)
        }
        
    }
}

