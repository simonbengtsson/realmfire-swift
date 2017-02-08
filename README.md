# RealmFire for Swift
RealmFire's aim is to automatically sync a local realm database with firebase.

*NOTE! This is an inofficial library which currently is nothing more then a proof of concept. Feel free to post issues if you have any feedback or let me know that you aim to use it and for what.*

The library offers similar functionality as the Realm Mobile Platform which is the official realm sync solution and is the better choice in most cases. RealmFire is useful when you are already invested in firebase or if you are developing a service for platforms not supported by Realm Mobile Platform such as the web.

The advantage of using realm, and not only the firebase sdk, is that you get an offline first application. It will sync data when network is available, but it can handle months without any connection if necessary.

## Integration
1. Download the repository and add the RealmFire folder to your project (package manager support is WIP, see #1)
2. Extend `SyncObject` instead of `Object` to map that class to a firebase collection
3. After updating a realm object, call `RealmFire.markForSync(object)` or `RealmFire.markForDeletion(object)` in a write transaction to sync that object the next sync.
4. Call `RealmFire.sync()` to sync. This will both fetch changes from firebase and upload local changes. 

Only tested with `Swift 3`, `RealmSwift 2.4.2` and `Firebase SDK 3.12.0`

## Usage example
Below is a minimal usage example. Take a look at the the demo project for more details.

```swift
// AppDelegate.swift
FIRApp.configure()

RealmFire.startSync

// Person.swift
class Person: SyncObject {
    dynamic var name = ""
    dynamic var age = 0
}

// ViewController.swift

let realm = try! Realm()
try! realm.write {
    let person = realm.create(Person.self)
    person.name = "John"
    person.age = 25
    person.markForSync()

    // Marking for sync will uploaded it at the next sync 
    person.markForSync()
}

// The sync call attempts to sync all objects marked for synced
RealmFire.sync(realm, firDatabase)

```

## Reference

#### RealmFire.swift
The main class containing all public api methods
- `RealmFire.sync()` Uploads local changes and fetches firebase updates
- `RealmFire.markForSync(objects)` Adds the specified `SyncObjects` to the sync queue.
- `RealmFire.markForDeletion(objects)` Adds the specified `SyncObjects` to the deletion queue.

#### SyncObject.swift
A `SyncObject` is an `Object` which maps to a specific firebase collection.
- `primaryKey()` The primary key of a realm object will also be used as primary key for the firebase collection. Required to be overriden by `SyncObject` subclasses.
- `collectionName()` Override to specify a custom firebase collection name. Default is the class name.
- `customAttributes()` Override to specify custom attribute name mappings between firebase and realm.
- `encode(prop: Property)` and `decode(prop: Property)` Override for customized object encoding/decoding
- `uploadedAtAttribute()` Override to rename the attribute which the library uses to query only changed objects

## Sync Error Behavior
The default behavior of RealmFire is to silently ignore errors. If you want to show the user that an error occured you can set a custom error reporter with `RealmFire.setErrorHandler()`. 

## Sync Behavior
This library automatically resolves sync conflicts with a best guess attitude. Currently this means that the object which is last sent to firebase will always win. There are plans to implement a somewhat better sync strategy based on when objects were modified, see #2.

RealmFire handles deletions by adding a deleted_at flag to each object and then syncing this to clients.

## Before alpha release
- Change `SyncMeta` to dictionary based
- Sync deletions from firebase to realm (force soft delete?)
- Write inline code comments for design descisions
- Tests for `Syncer`
- Tests for `Meta`
- Make sure `Mapper` tests make sense

## Future work
- Research how to add lib to cocoa pods, see complications here https://github.com/CocoaPods/CocoaPods/issues/5368
- Make it possible to ask lib about syncing status
- Sync subsets of SyncObject classes to different firebsae apps
- Add way to not force user to create Object subclasses for readonly objects
    - The idea is to use `Mapper` to convert between Dictionary and Object
    - Will probably be repressented by the Object subclass DataObject
- Wait to apply changes until all relationships are fetched (`udpatedAt` prop)
- Consider helping user setup automatic sync
- Consider adding option for syncing when internet is back

## Contributions
I will most likely not merge any pull request until I have decided upon an initial design for the API. Feel free fork the library and use the code however you wish however.
