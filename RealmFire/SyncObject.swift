import Foundation
import RealmSwift
import Realm
import Firebase

open class SyncObject: DataObject {

    public final func key() -> String {
        return self[type(of: self).primaryKey()!] as! String
    }

    /// Override this method to specify the name of the Firebase collection to use for this class.
    /// The class name is used by default if this method is not overriden.
    open class func collectionName() -> String {
        return self.className()
    }
    
    /// Override this method to specify the name of the uploadedAt attribute. It is used for
    /// selectively downloading only updated firebase objects. Default is "uploadedAt"
    open class func uploadedAtAttribute() -> String {
        return "uploadedAt"
    }
    
    /// Override this method to specify the name of the soft delete attribute. It is used for
    /// syncing deletions from firebase to realm. Default is "deletedAt"
    open class func softDeleteAttribute() -> String {
        return "deletedAt"
    }
    
    /* TODO
    /// Override this method to specify a property containing a date for when the model was last 
    /// updated. RealmFire will automatically set this when you call RealmFire improve the merge behavior.
    open class func uploadedAtAttribute() -> String? {
        return nil
    }
    */
}
