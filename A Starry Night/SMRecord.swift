//
//  SMRecord.swift
//  A Starry Night
//
//  Created by Christy Garreau on 11/1/19.
//  Copyright © 2019 Christy Garreau. All rights reserved.
//SporkVN is released under the MIT License
//
//Copyright (c) 2011-2016 James Briones
//
//Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
//
//The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
//

import Foundation
import UIKit

let SMRecordAutosaveSlotNumber = 0
let SMRecordHighScoreKey = "the high score"
let SMRecordDateSavedKey = "date saved"
let SMRecordCurrentSlotKey = "current slot"
let SMRecordUsedSlotNumbersKey = "used slots array"
let SMRecordDataKey = "record"
let SMRecordCurrentScoreKey = "current score"
let SMRecordFlagsKey = "flag data"
let SMRecordDateSavedAsString = "date saved as string"
let SMRecordSpriteAliasesKey = "sprite aliases"
let SMRecordCurrentActivityDictKey = "current activity"
let SMRecordActivityTypeKey = "activity type"
let SMRecordActivityDataKey = "activity data"

private let SMRecordSharedInstance = SMRecord()

class SMRecord {
    class var sharedRecord:SMRecord {
        return SMRecordSharedInstance
    }
    var record      = NSMutableDictionary(capacity: 1)
    var currentSlot = Int(0)
    init() {
        currentSlot = SMRecordAutosaveSlotNumber
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
    
    func stringFromDate(date:Date) -> String {
        let format          = DateFormatter()
        format.dateFormat   = "yyyy'-'MM'-'dd',' h:mm a"
        return format.string(from: date)
    }

    func updateDateInDictionary(dictionary:NSDictionary) {
        let theTimeRightNow:Date    = Date()
        let stringWithCurrentTime   = stringFromDate(date: theTimeRightNow)
        dictionary.setValue(theTimeRightNow,        forKey:SMRecordDateSavedKey)        // Save NSDate object
        dictionary.setValue(stringWithCurrentTime,  forKey:SMRecordDateSavedAsString)   // Save human-readable string
    }

    func emptyRecord() -> NSMutableDictionary {
        let tempRecord = NSMutableDictionary()
        tempRecord.setValue(NSNumber(value: 0), forKey:SMRecordCurrentScoreKey)
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
    
    func flags() -> NSMutableDictionary {
        if record.count < 0 {
            startNewRecord()
        }
        
        if let allMyFlags = record.object(forKey: SMRecordFlagsKey) as? NSMutableDictionary {
            return allMyFlags
        }
        
        // In this case, there are no flags at all, so create a new dictionary and just return that
        let emptyFlags = NSMutableDictionary(object: "dummy value - flags", forKey: "dummy key" as NSCopying)
        record.setValue(emptyFlags, forKey: SMRecordFlagsKey)
        return emptyFlags
    }
    
    // Set the "flags" mutable dictionary in the record. If there's no record, it just gets created on the fly
    func setFlags(dictionary:NSMutableDictionary) {
        if record.count < 1 {
            record = emptyRecord()
        }
        
        // Flags will only get updated if the dictionary is valid
        record.setValue(dictionary, forKey: SMRecordFlagsKey)
    }
    
    // MARK: - Slot functions
    
    // This grabs an NSArray (filled with NSNumbers) from NSUserDefaults. The array keeps track of which "slots" have
    // saved game information stored in them.
    func arrayOfUsedSlotNumbers() -> NSArray? {
        // The array is considered a "global" value (that is, the same value is stored across multiple playthrough/saved-games)
        // so it would be found under the root dictionary of NSUserDefaults for this app.
        let deviceMemory:UserDefaults = UserDefaults.standard //[NSUserDefaults standardUserDefaults];
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
        
        // If the number has already been used, then there's no point adding another mention of it; that would
        // up more memory to tell SMRecord something that it already knows. Information will only be added
        // if the slot number in question hasn't been used yet.
        if( numberWasAlreadyUsed == false ) {
            print("[SMRecord] Slot number \(slotNumber) has not been used previously.")
            let slotNumbersArray:NSMutableArray = NSMutableArray() //[[NSMutableArray alloc] init];
            
            // Check if there was any previous data. If there was, then it'll be added to the new array. If not... well, it's not a big deal!
            if let previousSlotsArray = self.arrayOfUsedSlotNumbers() {
                slotNumbersArray.addObjects(from: previousSlotsArray as [AnyObject])
            }
            
            // Add the slot number that was passed in to the newly-created array
            //[slotNumbersArray addObject:@(slotNumber)];
            slotNumbersArray.add(NSNumber(value: slotNumber))
            
            // Create a regular non-mutable NSArray and store the data there
            let unmutableArray:NSArray = NSArray(array: slotNumbersArray) //[[NSArray alloc] initWithArray:slotNumbersArray];
            let deviceMemory:UserDefaults = UserDefaults.standard // Pointer to NSUserDefaults
            deviceMemory.setValue(unmutableArray, forKey: SMRecordUsedSlotNumbersKey)
            print("[SMRecord] Slot number \(slotNumber) saved to array of used slot numbers.")//, (unsigned long)slotNumber);
        }
    }

    func setHighScoreWithInteger(integer:Int) {
        let theUserDefaults = UserDefaults.standard
        let theHighScore = NSNumber(value: integer) // Used to be unsigned, now regularly signed (theoretically a 64-bit integer)
        theUserDefaults.setValue(theHighScore, forKey: SMRecordHighScoreKey)
        
        /** WARNING: For some reason, the high score isn't being saved to NSUserDefaults anymore, so for now I'm
         saving it into the record along with normal data. **/
        record.setValue(theHighScore, forKey: SMRecordHighScoreKey)
    }
    
    func highScore() -> Int {
        var result:Int = 0; // The default value for the "high score" is zero
        if let theHighScore = record.object(forKey: SMRecordHighScoreKey) as? NSNumber {
            result = theHighScore.intValue
        } else {
            print("[SMRecord] WARNING: High score could not retrieved.")
        }
        return result;
    }
    
    func setCurrentScoreWithInteger(integer:Int) {
        if( record.count < 1 ) {
            //record = [[NSMutableDictionary alloc] initWithDictionary:[self emptyRecord]];
            record = emptyRecord()
        }
        record.setValue(NSNumber(value: integer), forKey:SMRecordCurrentScoreKey)
    }
    
    func currentScore() -> Int {
        if( record.count > 0 ) {
            if let scoreFromRecord = record.object(forKey: SMRecordCurrentScoreKey) as? NSNumber {
                return scoreFromRecord.intValue
            }
        }
        return 0
    }
    
    func dataFromSlot(slotNumber:Int) -> Data? {
        let deviceMemory:UserDefaults = UserDefaults.standard   // Pointer to where memory is stored in the device
        let slotKey = NSString(string: "slot\(slotNumber)") // Generate name of the dictionary key where save data is stored
        
        print("[SMRecord] Loading record from slot named [\(slotKey)]")
        
        if let slotData = deviceMemory.object(forKey: slotKey as String) as? Data {
            print("[SMRecord] 'dataFromSlot' has loaded an NSData object of size \(slotData.count) bytes.")
            return (NSData(data: slotData) as Data)
        }
        
        print("[SMRecord] ERROR: No data found in slot number \(slotNumber)")
        return nil;
    }
    
    func recordFromData(data:Data) -> NSDictionary? {
        let unarchiver = try! NSKeyedUnarchiver(forReadingFrom: data)
        unarchiver.requiresSecureCoding = false
        if let dictionaryFromData = unarchiver.decodeObject(forKey: SMRecordDataKey) as? NSDictionary {
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
        archiver.finishEncoding() //[archiver finishEncoding];
        return archiver.encodedData
    }
    
    func saveData(data:Data, slotNumber:Int) {
        let deviceMemory            = UserDefaults.standard
        let stringWithSlotNumber    = NSString(string: "slot\(slotNumber)") // Dictionary key for slot
        deviceMemory.setValue(data, forKey: stringWithSlotNumber as String) // Store data in NSUserDefaults dictionary
        self.addToUsedSlotNumbers(slotNumber: slotNumber)                   // flag this slot number as being used
    }
    
    // Updates the high score if highest score
    func updateHighScore() {
        let theCurrentScore = currentScore() //[self currentScore];
        let theHighScore    = highScore()
        if( theCurrentScore > theHighScore ) {
            self.setHighScoreWithInteger(integer: theCurrentScore)
        }
    }
    
    func saveCurrentRecord() {
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
        
        // Update record information
        self.updateDateInDictionary(dictionary: record)
        self.updateHighScore() //updateHighScore()
        
        let recordAsData = self.dataFromRecord(dictionary: record)
        self.saveData(data: recordAsData, slotNumber: currentSlot)
    }
    
    func spriteAliases() -> NSMutableDictionary {
        // check if the dictionary already exists, and if so, return it
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

