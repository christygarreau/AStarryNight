//
//  SMRecord.h
//
//  Created by James Briones on 2/5/11.
//  Copyright 2011. All rights reserved.
//

import Foundation
import UIKit

let SMRecordAutosaveSlotNumber      = 0
let SMRecordHighScoreIntegerKey     = "the high score integer"
let SMRecordHighScoreStringKey      = "the high score string"
let SMRecordDateSavedKey            = "date saved"
let SMRecordCurrentSlotKey          = "current slot"
let SMRecordUsedSlotNumbersKey      = "used slots array"

let SMRecordDataKey                 = "record"
let SMRecordCurrentIntegerScoreKey  = "current integer score"
let SMRecordCurrentStringScoreKey   = "current string score"
let SMRecordFlagsKey                = "flag data"
let SMRecordDateSavedAsString       = "date saved as string"
let SMRecordSpriteAliasesKey        = "sprite aliases"

let SMRecordCurrentActivityDictKey  = "current activity"
let SMRecordActivityTypeKey         = "activity type"
let SMRecordActivityDataKey         = "activity data"

private let SMRecordSharedInstance = SMRecord()

class SMRecord {
    class var sharedRecord:SMRecord {
        return SMRecordSharedInstance
    }
    var record      = NSMutableDictionary(capacity: 1)
    var currentSlot = Int(0)
    
    // Initialization
    
    init() {
        currentSlot = SMRecordAutosaveSlotNumber // ZERO
        let userDefaults:UserDefaults = UserDefaults.standard
        if let lastSavedSlot = userDefaults.object(forKey: SMRecordCurrentSlotKey) as? NSNumber {
            self.currentSlot = lastSavedSlot.intValue
            print("[SMRecord] Current slot set to \(self.currentSlot), which was the value stored in memory.")
        }
        if self.hasAnySavedData() == true {
            if let allUsedSlots = self.arrayOfUsedSlotNumbers() {
                print("[SMRecord] The following slots are in use: \(String(describing: allUsedSlots))")
            }
            self.loadRecordFromCurrentSlot()
            if( record.count > 0 ) {
                print("[SMRecord] Record initialized with data: \(record)")
            } else {
                print("[SMRecord] Failed to initialize saved game data.");
            }
        }
    }
    
    // Date and time
    
    func stringFromDate(date:Date) -> String {
        let format          = DateFormatter()
        format.dateFormat   = "yyyy'-'MM'-'dd',' h:mm a" // Example: "2014-11-11, 12:29 PM"
        return format.string(from: date)
    }
    
    func updateDateInDictionary(dictionary:NSDictionary) {
        let theTimeRightNow:Date    = Date()
        let stringWithCurrentTime   = stringFromDate(date: theTimeRightNow)
        
        dictionary.setValue(theTimeRightNow,        forKey:SMRecordDateSavedKey)
        dictionary.setValue(stringWithCurrentTime,  forKey:SMRecordDateSavedAsString)
    }
    
    // Record
    
    func emptyRecord() -> NSMutableDictionary {
        let tempRecord = NSMutableDictionary()
        tempRecord.setValue(NSNumber(value: 100), forKey:SMRecordCurrentIntegerScoreKey)
        tempRecord.setValue(NSString(string: "+A"), forKey:SMRecordCurrentStringScoreKey)
        updateDateInDictionary(dictionary: tempRecord)
        self.resetActivityInformation(inDictionary: tempRecord)
        
        let tempFlags = NSMutableDictionary(object: "dummy value - empty record", forKey: "dummy key" as NSCopying)
        tempRecord.setValue(tempFlags, forKey:SMRecordFlagsKey)
        return tempRecord
    }
    
    func startNewRecord() {
        record = NSMutableDictionary(dictionary: emptyRecord())
        UserDefaults.standard.setValue(currentSlot, forKey: SMRecordCurrentSlotKey)
    }
    
    func hasAnySavedData() ->Bool {
        var result = true;
        let lastSavedDate:Date? = UserDefaults.standard.object(forKey: SMRecordDateSavedKey) as? Date
        let usedSlotNumbers:NSArray? = arrayOfUsedSlotNumbers()
        if( lastSavedDate == nil || usedSlotNumbers == nil ) {
            result = false;
        }
        return result;
    }
    
    // Flags
    
    func flags() -> NSMutableDictionary {
        if record.count < 0 {
            startNewRecord()
        }
        if let allMyFlags = record.object(forKey: SMRecordFlagsKey) as? NSMutableDictionary {
            return allMyFlags
        }
        
        let emptyFlags = NSMutableDictionary(object: "dummy value - flags", forKey: "dummy key" as NSCopying)
        record.setValue(emptyFlags, forKey: SMRecordFlagsKey)
        return emptyFlags
    }
    
    func setFlags(dictionary:NSMutableDictionary) {
        if record.count < 1 {
            record = emptyRecord()
        }
        record.setValue(dictionary, forKey: SMRecordFlagsKey)
    }
    
    // Slot functions
    
    func arrayOfUsedSlotNumbers() -> NSArray? {
        let deviceMemory:UserDefaults = UserDefaults.standard
        let tempArray:NSArray? = deviceMemory.object(forKey: SMRecordUsedSlotNumbersKey) as? NSArray
        if( tempArray == nil ) {
            print("[SMRecord] Cannot find a previously existing array of used slot numbers.");
            return nil
        }
        return tempArray
    }
    
    func slotNumberHasBeenUsed(number:Int) -> Bool {
        var result = false
        let slotsUsed:NSArray? = arrayOfUsedSlotNumbers()
        if( slotsUsed == nil || slotsUsed!.count < 1 ) {
            return result
        }
        
        for i in 0 ..< slotsUsed!.count {
            let currentNumber:NSNumber = slotsUsed!.object(at: i) as! NSNumber
            let valueOfCurrentNumber:Int = currentNumber.intValue
            if( valueOfCurrentNumber == number ) {
                print("[SMRecord] Match found for slot number \(number) in index \(i)")
                result = true; // This slot number has indeed been used
            }
        }
        
        return result;
    }
    
    func addToUsedSlotNumbers(slotNumber:Int) {
        print("[SMRecord] Will now attempt to add \(slotNumber) to array of used slot numbers.")
        let numberWasAlreadyUsed:Bool = slotNumberHasBeenUsed(number:slotNumber)
        if( numberWasAlreadyUsed == false ) {
            print("[SMRecord] Slot number \(slotNumber) has not been used previously.")
            let slotNumbersArray:NSMutableArray = NSMutableArray()
            if let previousSlotsArray = self.arrayOfUsedSlotNumbers() {
                slotNumbersArray.addObjects(from: previousSlotsArray as [AnyObject])
            }
            slotNumbersArray.add(NSNumber(value: slotNumber))
            let unmutableArray:NSArray = NSArray(array: slotNumbersArray)
            let deviceMemory:UserDefaults = UserDefaults.standard
            deviceMemory.setValue(unmutableArray, forKey: SMRecordUsedSlotNumbersKey)
            print("[SMRecord] Slot number \(slotNumber) saved to array of used slot numbers.")
        }
    }
    
    // Score
    
    // Sets the high score (stored in NSUserDefaults)
    func setHighScore(integer:Int,str:String) {
        // Remember that the High Score is a global value and should be stored directly in NSUserDefaults instead of the slot/record section
        let theUserDefaults = UserDefaults.standard
        let theHighScoreInteger = NSNumber(value: integer)
        let theHighScoreString = NSString(string: str)
        theUserDefaults.setValue(theHighScoreInteger, forKey: SMRecordHighScoreIntegerKey)
        theUserDefaults.setValue(theHighScoreString, forKey: SMRecordHighScoreStringKey)
        
        record.setValue(theHighScoreInteger, forKey: SMRecordHighScoreIntegerKey)
        record.setValue(theHighScoreString, forKey: SMRecordHighScoreStringKey)
    }
    
    func highScoreInteger() -> Int {
        var result:Int = 0;
        if let theHighScoreInteger = record.object(forKey: SMRecordHighScoreIntegerKey) as? NSNumber {
            result = theHighScoreInteger.intValue
        } else {
            print("[SMRecord] WARNING: High score integer could not retrieved.")
        }
        return result;
    }
    
    func highScoreString() -> String {
        var result:String = "F";
        var intResult:Int = 0;
        if let theHighScoreString = record.object(forKey: SMRecordHighScoreStringKey) as? NSString, let theHighScoreInteger = record.object(forKey:SMRecordHighScoreIntegerKey) as? NSNumber {
            result = theHighScoreString as String
            intResult = Int(theHighScoreInteger)
            if intResult >= 97{
                result = "+A"
            } else if intResult >= 93{
                result = "A"
            } else if intResult >= 90{
                result = "-A"
            } else if intResult >= 87{
                result = "+B"
            } else if intResult >= 83{
                result = "B"
            } else if intResult >= 80{
                result = "-B"
            } else if intResult >= 77{
                result = "+C"
            } else if intResult >= 73{
                result = "C"
            } else if intResult >= 70{
                result = "-C"
            } else if intResult >= 67{
                result = "+D"
            } else if intResult >= 63{
                result = "D"
            } else if intResult >= 60{
                result = "-D"
            } else if intResult < 60{
                result = "F"
            }
            print("\(intResult),\(result)")
        } else {
            print("[SMRecord] WARNING: High score string could not retrieved.")
        }
        return result;
    }
    
    func setCurrentScore(integer:Int,str:String) {
        if( record.count < 1 ) {
            record = emptyRecord()
        }
        record.setValue(NSString(string: str), forKey:SMRecordCurrentStringScoreKey)
        record.setValue(NSNumber(value: integer), forKey:SMRecordCurrentIntegerScoreKey)
    }
    
    func currentIntegerScore() -> Int {
        if( record.count > 0 ) {
            if let scoreFromRecord = record.object(forKey: SMRecordCurrentIntegerScoreKey) as? NSNumber {
                return scoreFromRecord.intValue
            }
        }
        return 100
    }
    
    func currentStringScore() -> String {
        if currentIntegerScore() >= 97{
            return "+A"
        } else if currentIntegerScore() >= 93{
            return "A"
        } else if currentIntegerScore() >= 90{
            return "-A"
        } else if currentIntegerScore() >= 87{
            return "+B"
        } else if currentIntegerScore() >= 83{
            return "B"
        } else if currentIntegerScore() >= 80{
            return "-B"
        } else if currentIntegerScore() >= 77{
            return "+C"
        } else if currentIntegerScore() >= 73{
            return "C"
        } else if currentIntegerScore() >= 70{
            return "-C"
        } else if currentIntegerScore() >= 67{
            return "+D"
        } else if currentIntegerScore() >= 63{
            return "D"
        } else if currentIntegerScore() >= 60{
            return "-D"
        } else if currentIntegerScore() < 60{
            return "F"
        }
        print("\(currentStringScore())")
        
        return "+A"
    }
    
    // NSData handling
    
    func dataFromSlot(slotNumber:Int) -> Data? {
        let deviceMemory:UserDefaults = UserDefaults.standard
        let slotKey = NSString(string: "slot\(slotNumber)")
        print("[SMRecord] Loading record from slot named [\(slotKey)]")
        
        if let slotData = deviceMemory.object(forKey: slotKey as String) as? Data {
            print("[SMRecord] 'dataFromSlot' has loaded an NSData object of size \(slotData.count) bytes.")
            return (NSData(data: slotData) as Data)
        }
        
        print("[SMRecord] ERROR: No data found in slot number \(slotNumber)")
        return nil;
    }
    
    func recordFromData(data:Data) -> NSDictionary? {
        let unarchiver                  = try! NSKeyedUnarchiver(forReadingFrom: data)
        unarchiver.requiresSecureCoding = false
        if let dictionaryFromData       = unarchiver.decodeObject(forKey: SMRecordDataKey) as? NSDictionary {
            unarchiver.finishDecoding()
            print("Dictionary from data: \(dictionaryFromData)")
            return NSDictionary(dictionary: dictionaryFromData)
        }
        print("[SMRecord] Can't retrieve record from data object.")
        return nil
    }
    
    func recordFromSlot(number:Int) -> NSDictionary? {
        if let loadedData = self.dataFromSlot(slotNumber: number) {
            return self.recordFromData(data: loadedData)
        }
        return nil
    }
    
    func loadRecordFromCurrentSlot() {
        if let temporaryDictionary = self.recordFromSlot(number: currentSlot) {
            record = NSMutableDictionary(dictionary: temporaryDictionary)
            print("[SMRecord] Record was successfully loaded from slot \(self.currentSlot)")
        } else {
            print("[SMRecord] ERROR: Could not load record from slot \(self.currentSlot)")
        }
    }
    
    func dataFromRecord(dictionary:NSDictionary) -> Data {
        self.updateDateInDictionary(dictionary: dictionary)
        let archiver = NSKeyedArchiver(requiringSecureCoding: false)
        archiver.encode(dictionary, forKey: SMRecordDataKey)
        archiver.finishEncoding()
        return archiver.encodedData
    }
    
    func saveData(data:Data, slotNumber:Int) {
        let deviceMemory            = UserDefaults.standard
        let stringWithSlotNumber    = NSString(string: "slot\(slotNumber)")
        deviceMemory.setValue(data, forKey: stringWithSlotNumber as String)
        self.addToUsedSlotNumbers(slotNumber: slotNumber)
    }
    
    // DONT CALL THIS MID GAME
    func updateHighScore() {
        let theCurrentIntegerScore = currentIntegerScore() //[self currentScore];
        let theIntegerHighScore    = highScoreInteger()
        
        if( theCurrentIntegerScore > theIntegerHighScore ) {
            self.setHighScore(integer: theCurrentIntegerScore, str: highScoreString())//the highscorestring might not work - have to add code to sethighscore
        }
    }
    
    func saveCurrentRecord() {//doesn't update the high score //HELP
        if( record.count < 1 ) {
            print("[SMRecord] ERROR: No record data exists.");
            return;
        }
        
        // Update global data
        let deviceMemory = UserDefaults.standard
        let theDateToday = Date()
        let theSlotToUse = NSNumber(value: currentSlot)
        deviceMemory.setValue(theDateToday, forKey: SMRecordDateSavedKey)
        deviceMemory.setValue(theSlotToUse, forKey: SMRecordCurrentSlotKey)
        
        self.updateDateInDictionary(dictionary: record)
        //self.updateHighScore() //updateHighScore()
        
        let recordAsData = self.dataFromRecord(dictionary: record)
        self.saveData(data: recordAsData, slotNumber: currentSlot)
    }
    
    // Sprite aliases
    
    // Retrieve sprite alias data rom record and return it in a mutable dictionary
    func spriteAliases() -> NSMutableDictionary {
        if let aliasesFromDictionary = record.object(forKey: SMRecordSpriteAliasesKey) as? NSMutableDictionary {
            return aliasesFromDictionary
        }
        
        // otherwise, the dictionary will have to be created inside of the record
        let aliasDictionary = NSMutableDictionary()
        record.setValue(aliasDictionary, forKey:SMRecordSpriteAliasesKey)
        
        return aliasDictionary
    }
    
    // Replace the existing sprite alias dictionary with another dictionary
    func setSpriteAliases(dictionary:NSMutableDictionary) {
        if record.count < 0 {
            self.startNewRecord()
        }
        record.setValue(dictionary, forKey:SMRecordSpriteAliasesKey)
    }
    
    // Remove all of the sprite alias data from the dictionary
    func resetAllSpriteAliases() {
        let dummyAliases = NSMutableDictionary()
        dummyAliases.setValue("dummy sprite alias value", forKey:"dummy alias key");
        self.setSpriteAliases(dictionary: dummyAliases)
    }
    
    // Add sprite alias data from another dictionary to the dictionary stored by the record
    func addExistingSpriteAliases(dictionary:NSDictionary) {
        if dictionary.count > 0 {
            let spriteAliasDictionary = self.spriteAliases()
            SMDictionaryAddEntriesFromAnotherDictionary(spriteAliasDictionary, source: dictionary)
        }
    }
    
    // Add a single sprite alias to the dictionary of sprite aliases stored by the record
    func setSpriteAlias(named:String, withUpdatedValue:String) {
        if SMStringLength(named) < 1 || SMStringLength(withUpdatedValue) < 1 {
            return
        }
        
        let allSpriteAliases = self.spriteAliases()
        allSpriteAliases.setValue(withUpdatedValue, forKey: named)
    }
    
    // Return information about a particular sprite alias
    func spriteAliasNamed(name:String) -> String? {
        if record.count < 1 {
            return nil
        }
        
        let allSpriteAliases    = self.spriteAliases()
        let specificAlias       = allSpriteAliases.object(forKey: name) as? String
        
        return specificAlias
    }
    
    // MARK: - Flags
    
    /*
     Opens a PLIST file and copies all items in it to EKRecord as flags.
     
     Can choose whether or not to overwrite existing flags that have the same names.
     */
    func addFlagsFromFile(named:String, overrideExistingFlags:Bool) {
        let rootDictionary = SMDictionaryFromFile(named)
        if rootDictionary == nil {
            print("[EKRecord] WARNING: Could not load flags as the dictionary file could not be loaded.")
            return;
        }
        
        if overrideExistingFlags == true {
            print("[EKRecord] DIAGNOSTIC: Will forcibly overwrite existing flags with flags from file: \(named)")
        } else {
            print("[EKRecord] DIAGNOSTIC: Will add flags (without overwriting) from file named: \(named)")
        }
        
        for key in rootDictionary!.allKeys {
            let value = rootDictionary!.object(forKey: key)
            
            if overrideExistingFlags == true {
                //self.setFlagValue(value! as AnyObject, nameOfFlag: key as! String)
                self.setFlagValue(object: value! as AnyObject, flagNamed: key as! String)
                //self.setFlagValue(value!, forFlagNamed:key)
            } else {
                //let existingFlag = self.flagNamed(key as! String)
                let existingFlag = self.flagNamed(string: key as! String)
                if existingFlag == nil {
                    //self.setValue(value!, forFlagNamed:key as! String)
                    //setFlagValue(value! as AnyObject, nameOfFlag: key as! String)
                    self.setFlagValue(object: value! as AnyObject, flagNamed: key as! String)
                }
            }
        } // end for loop
    } // end function
    
    
    // This removes any existing flag data and overwrites it with a blank dictionary that has dummy values
    func resetAllFlags() {
        // Create a brand-new dictionary with nothing but dummy data
        //NSMutableDictionary* dummyFlags = [[NSMutableDictionary alloc] init];
        //[dummyFlags setValue:@"dummy value" forKey:@"dummy key"];
        let dummyFlags = NSMutableDictionary()
        dummyFlags.setValue(NSString(string: "dummy value - reset all flags"), forKey: "dummy key")
        
        // Set this "dummy data" dictionary as the flags data
        //[self setFlags:dummyFlags];
        //setFlags(dummyFlags)
        self.setFlags(dictionary: dummyFlags)
    }
    
    
    
    // Adds a dictionary of flags to the Flags data stored in SMRecord
    func addExistingFlags(fromDictionary:NSDictionary) {
        // Check if there's not really any data to add
        if( fromDictionary.count < 1 ) {
            return;
        }
        
        // Check if no record data exists. If that's the case, then start a new record.
        if( record.count < 1 ) {
            //[self startNewRecord];
            startNewRecord()
        }
        
        // Add these new dictionary values to any existing flag data
        let flagsDictionary = self.flags()
        flagsDictionary.addEntries(from: fromDictionary as! [AnyHashable: Any])
    }
    
    func flagNamed(string:String) -> AnyObject? {
        return self.flags().object(forKey: string) as AnyObject?
    }
    
    // Return the int value of a particular flag. It's important to keep in mind though, that while flags by default
    // use int values, it's entirely possible that it might use something entirely different. It's even possible to use
    // completely different types of objects (say, UIImage) as a flag value.
    func valueOfFlagNamed(string:String) -> Int {
        if let theFlag = self.flagNamed(string: string) as? NSNumber {
            // determine if the flag actually contains a numerical value
            if theFlag.isKind(of: NSNumber.self) == true {
                return theFlag.intValue
            } else {
                // this flag probably contains a string, or maybe even something else entirely
                print("[SMRecord] WARNING: Attempt to retrieve value of flag named \(string), but this flag does not contain numerical data.")
            }
        }
        
        return 0 // default value is zero
    }
    
    // Sets the value of a flag
    func setFlagValue(object:AnyObject, flagNamed:String) {
        // Create valid record if one doesn't exist
        if( record.count < 1 ) {
            startNewRecord()
        }
        
        // Update flags dictionary with this value
        let theFlags = self.flags()
        theFlags.setValue(object, forKey: flagNamed)
    }
    
    // Sets a flag's int value. If you want to use a non-integer value (or something that's not even a number to begin with),
    // then you shoule switch to 'setFlagValue' instead.
    func setFlagValueWithInteger(integer:Int, flagNamed:String) {
        // Convert int to NSNumber and pass that into the flags dictionary
        let tempValue = NSNumber(value: integer)
        self.setFlagValue(object: tempValue, flagNamed: flagNamed)
    }
    
    // Adds or subtracts the integer value of a flag by a certain amount (the amount being whatever 'iValue' is).
    //func modifyIntegerValue(_ iValue:Int, nameOfFlag:String) {
    func modifyFlagWithInteger(integer:Int, flagNamed:String) {
        var modifiedInteger:Int = 0
        
        // Create a record if there isn't one already
        if( record.count < 1 ) {
            startNewRecord()
        }
        
        if let numberObject = self.flags().object(forKey: flagNamed) as? NSNumber {
            if numberObject.isKind(of: NSNumber.self) {
                modifiedInteger = numberObject.intValue
            }
        }
        
        modifiedInteger = modifiedInteger + integer
        self.setFlagValue(object: NSNumber(value: modifiedInteger), flagNamed: flagNamed)
    }
    
    // MARK: - Activity data
    
    // Sets the activity information in the record
    func setActivityDictionary(dictionary:NSDictionary) {
        // Check if there's no data
        if( dictionary.count < 1 ){
            print("[SMRecord] ERROR: Invalid activity dictionary was passed in; nothing will be done.")
            return;
        }
        
        // Check if the record is empty
        if record.count < 1 {
            startNewRecord()
        }
        
        // Store a copy of the dictionary into the record
        let dictionaryToStore = NSDictionary(dictionary: dictionary)
        record.setValue(dictionaryToStore, forKey: SMRecordCurrentActivityDictKey)
    }
    
    // Return activity data from record
    func dictionaryOfActivityInformation() -> NSDictionary {
        // Check if the record exists, and if so, then try to grab the activity data from it. By default, there should be some sort of dictionary,
        // even if it's just nothing but dummy values.
        if( record.count > 0 ) {
            if let retrievedDictionary = record.object(forKey: SMRecordCurrentActivityDictKey) as? NSDictionary {
                return NSDictionary(dictionary: retrievedDictionary)
            }
        }
        
        // Otherwise, return empty dictionary
        return NSDictionary()
    }
    
    // This just resets all the activity information stored by a particular dictionary back to its default values (that is, "dummy" values).
    // The "dict" being passed in should be a record dictionary of some kind (ideally, the 'record' dictionary stored by SMRecord)
    func resetActivityInformation(inDictionary:NSDictionary) {
        // Fill out the activity information with useless "dummy data." Later, this data can (and should) be overwritten there's actual data to use
        let informationAboutCurrentActivity = NSMutableDictionary(object: "nil", forKey: "scene to play" as NSCopying)
        let activityDictionary = NSMutableDictionary(objects: ["nil", informationAboutCurrentActivity],
                                                     forKeys: [SMRecordActivityTypeKey as NSCopying, SMRecordActivityDataKey as NSCopying])
        
        // Store dummy data into record
        inDictionary.setValue(activityDictionary, forKey: SMRecordCurrentActivityDictKey)
    }
    
    // For saving/loading to device. This should cause the information stored by SMRecord to being put to NSUserDefaults, and then
    // it would "synchronize," so that the data would be stored directly into the device memory (as opposed to just sitting in RAM).
    func saveToDevice() {
        print("[SMRecord] Will now attempt to save information to device memory.");
        
        if record.count < 1 {
            print("[SMRecord] ERROR: Cannot save information because no record exists.")
            return
        }
        
        print("[SMRecord] Saving record to device memory...");
        
        //[self saveCurrentRecord];
        saveCurrentRecord()
        
        // Now "synchronize" the data so that everything in NSUserDefaults will be moved from RAM into the actual device memory.
        // NSUserDefaults synchronizes its data every so often, but in this case it will be done manually to ensure that SMRecord's data
        // will be moved into device memory.
        //[[NSUserDefaults standardUserDefaults] synchronize];
        let didSync:Bool = UserDefaults.standard.synchronize()
        
        if didSync == false {
            print("[SMRecord] WARNING: Could not synchronize data to device memory.")
        } else {
            print("[SMRecord] Record was synchronized.")
        }
    } // end function
} // end class
