//
//  DatabaseManager.swift
//  Xchangerator
//
//  Created by 张一唯 on 2020-02-09.
//  Copyright © 2020 YYES. All rights reserved.
//

import Foundation
import FirebaseCore
import FirebaseUI
import FirebaseFirestore
import FirebaseFirestoreSwift

//Todo: Change from singleton to dependency injection with protocols
//https://swiftwithmajid.com/2019/03/06/dependency-injection-in-swift-with-protocols/

class DatabaseManager {
    static var shared = DatabaseManager()
    var db = Firestore.firestore()

    func registerUser(fcmToken firebaseMsgDeviceToken:String?,fbAuthRet authDataResult:AuthDataResult) {
        // [START add_ada_lovelace]
        /*
                    anonymous:BOOL
                    emailVerified:BOOL
                    refreshToken:NSString
                    providerData:NSArray https://firebase.google.com/docs/reference/ios/firebaseauth/api/reference/Protocols/FIRUserInfo.html
                    FIRUserMetadata:metadata
         r  */
        let user = authDataResult.user
          // The user's ID, unique to the Firebase project.
          // Do NOT use this value to authenticate with your backend server,
          // if you have one. Use getTokenWithCompletion:completion: instead.
        let uid = user.uid
        let userCollectionRef = db.collection("users")
        let userRef = userCollectionRef.document("\(Constant.xDBtokenPrefix)\(uid)")

        userRef.getDocument { (document, error) in
            var userProfile:User_Profile
            if let document = document, document.exists {
                //handle existing user
                let deviceTokens = document.get("deviceTokens") as? Array<String>
//                if (deviceTokens == nil || deviceTokens == "") {deviceTokens=[]}
                var newTokenArr = deviceTokens ?? Array<String>()
            
                if let wrappedFcmToken = firebaseMsgDeviceToken  {
                    if (!newTokenArr.contains(wrappedFcmToken)) {
                        newTokenArr.append(wrappedFcmToken)
                    }
                }
                newTokenArr = newTokenArr.filter{ $0 != "" }
                Logger.debug("Document data: \(newTokenArr)")
                
                userProfile = User_Profile(email:user.email ?? "Loyal_\(uid)@Xchangerator.com" ,photoURL:user.photoURL,deviceTokens:newTokenArr, name:user.displayName ?? "Loyal customer")
                
            } else {
                //create all the fields for the new user
                var newTokenArr = Array<String>()
                if let wrappedFcmToken = firebaseMsgDeviceToken  {
                        newTokenArr.append(wrappedFcmToken)
                }
                userProfile = User_Profile(email:user.email ?? "New_\(uid)@Xchangerator.com" ,photoURL:user.photoURL,deviceTokens:newTokenArr, name:user.displayName ?? "New User")
                //Todo:add subcollection and 5 sub doc
            }
            let userDoc = User_DBDoc(profile:userProfile)
            try? userRef.setData( from:userDoc ) { err in
                if let err = err {
                    Logger.error("Error adding document: \(err), and token \(String(describing: firebaseMsgDeviceToken))")
                } else {
                    Logger.info("Document added with ID: \(String(describing: userRef.documentID)), token:\(String(describing: firebaseMsgDeviceToken))")
                }
            }
        }
        // [END register User]
    }
    
}
