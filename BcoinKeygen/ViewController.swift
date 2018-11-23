/**
 *  Copyright (c) 2018 Provide Technologies Inc.
 *
 *  Licensed under the MIT license, as follows:
 *
 *  Permission is hereby granted, free of charge, to any person obtaining a copy
 *  of this software and associated documentation files (the "Software"), to deal
 *  in the Software without restriction, including without limitation the rights
 *  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 *  copies of the Software, and to permit persons to whom the Software is
 *  furnished to do so, subject to the following conditions:
 *
 *  The above copyright notice and this permission notice shall be included in all
 *  copies or substantial portions of the Software.
 *
 *  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 *  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 *  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 *  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 *  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 *  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 *  SOFTWARE.
 */

import UIKit
import LocalAuthentication
import provide

class ViewController: UIViewController {

    @IBOutlet weak var publicKeyField: UITextView!
    @IBOutlet weak var privateKeyField: UITextView!
    
    struct ECC {
        static let keypair: EllipticCurveKeyPair.Manager = {
            EllipticCurveKeyPair.logger = { print($0) }
            let publicAccessControl = EllipticCurveKeyPair.AccessControl(protection: kSecAttrAccessibleAlwaysThisDeviceOnly, flags: [])
            let privateAccessControl = EllipticCurveKeyPair.AccessControl(protection: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly, flags: {
                return EllipticCurveKeyPair.Device.hasSecureEnclave ? [.userPresence, .privateKeyUsage] : [.userPresence]
            }())
            let config = EllipticCurveKeyPair.Config(
                publicLabel: "services.provide.ecc.public",
                privateLabel: "services.provide.ecc.private",
                operationPrompt: "Sign transaction",
                publicKeyAccessControl: publicAccessControl,
                privateKeyAccessControl: privateAccessControl,
                token: .secureEnclaveIfAvailable)
            return EllipticCurveKeyPair.Manager(config: config)
        }()
    }

    // MARK: - Action Methods

    @IBAction func generateNewKeyPair(_sender: UIControl) {
        do {
            try ECC.keypair.deleteKeyPair()
            let secp256k1PublicKey = try ECC.keypair.publicKey().data()
            publicKeyField.text = ProvideBcoinService.shared.generateBcoinPublicKey(privateKey: secp256k1PublicKey.raw)

            let isPrivateKeyInEnclave = try ECC.keypair.privateKey().isStoredOnSecureEnclave()
            let storageLocationDescription = isPrivateKeyInEnclave ? "Stored in Secure Enclave" : "Stored in Keychain"
            var privateKeyDetails = "Unable to get private key details"
            if let details = try? ECC.keypair.privateKey().underlying {
                privateKeyDetails = "\(details)"
            }
            privateKeyField.text = "\(privateKeyDetails) \n\n(\(storageLocationDescription.lowercased()))"
        } catch {
            publicKeyField.text = "Error: \(error)"
            privateKeyField.text = ""
        }
    }
}
