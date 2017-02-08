import Foundation
import RealmSwift
import Realm
import Firebase

open class DataObject: Object {
    
    /// Custom attributes names on format [local property name : firebase attribute]
    open class func customAttributes() -> [String: String] {
        return [:]
    }
    
    /**
     Override this method to deserialize values coming from firebase.
     
     By default dates are deserialized from a unix timestamps in seconds
     
     - returns: If value has been encoded, uses global mapper if false
     */
    open func encode(prop: Property, result: inout [String: Any]) -> Bool {
        return false
    }
    
    /**
     Override this method to format specific values before the serialized object is sent to Firebase.
     
     By default dates are serialized as a unix timestamps in seconds.
     
     See which values are valid in the Firebase documentation:
     https://firebase.google.com/docs/database/ios/read-and-write
     
     Note that Double.nan and Double.infinity are invalid
     
     - returns: If value has been decoded, uses global mapper if false
     */
    open func decode(prop: Property, data: [String: Any]) -> Bool {
        return false
    }
    
    open class func ignoredSyncProperties() -> [String] {
        return []
    }
}
