//
//  DataManager.swift
//  SpacePod15
//
//  Created by Mattia Fochesato on 17/11/21.
//

import Foundation
import Combine
import SwiftUI

class DataManager: ObservableObject {
    
    //UserDefaults key for TaskInfo array
    private static let PREF_JSON_NAME = "app_json_data2"
    
    //All the tasks of the app
    @Published var tasks: [TaskInfo] = []
    
    //All the unlocked awards
    @Published var unlockedAwards: [UnlockedAward] = []
    
    var lastUnlockedAward: Award!
    
    //Init the class
    init() {
        print("[TasksManager] init()")
        //Load tasks from JSON
        self.loadDataFromJson()
        
        unlockedAwards = [UnlockedAward(awardName: "medGeografiaBronzo", date: Date()),
                          UnlockedAward(awardName: "medGeografiaArgento", date: Date()),
                          UnlockedAward(awardName: "medMatematicaBronzo", date: Date())]
    }
    
    func getDemoDataManager() -> DataManager {
        tasks.append(TaskInfo(id: UUID(), subject: "Italiano", name: "Studia Dante", taskEmoji: "🤌🏻", priority: .low, completed: Date(), date: nil))
        tasks.append(TaskInfo(id: UUID(), subject: "Storia", name: "Studia Ciccio Gamer", taskEmoji: "🤌🏻", priority: .low, completed: nil, date: Date()))
        return self
    }
    
    //Loads the data from the JSON data to restore all the tasks
    func loadDataFromJson() {
        let jsonData = UserDefaults.standard.string(forKey: DataManager.PREF_JSON_NAME)
        
        //Check jsonData is not nil and can be converted to Data
        guard let jsonData = jsonData, let jsonData = jsonData.data(using: .utf8) else {
            tasks = []
            return
        }
        
        //Convert jsonData to [TaskInfo] object
        do {
            //Native class to decode json
            let jsonDecoder = JSONDecoder()
            //Save the extracted tasks
            let jsonStruct = try jsonDecoder.decode(DataJSON.self, from: jsonData)
            self.tasks = jsonStruct.tasks
            self.unlockedAwards = jsonStruct.unlockedAwards
        }catch {
            //Decoding failed. Show error and return
            print("[TasksManager] Cannot decode JSON \(error)")
            tasks = []
            unlockedAwards = []
            return
        }
        
        print("[TasksManager] Loaded \(tasks.count) tasks from JSON")
        self.scheduleNotifications()
    }
    
    //Save all the tasks to the JSON file to keep all the info
    func saveDataToJson() {
        self.scheduleNotifications()
        //Native class to encode json
        let jsonEncoder = JSONEncoder()
        
        do {
            //Create a struct to save on a JSON string
            let jsonStruct = DataJSON(tasks: tasks, unlockedAwards: unlockedAwards)
            
            //Try to encode all the data to a json string
            let jsonData = try jsonEncoder.encode(jsonStruct)
            
            //Extract the String from a Data object
            let json = String(data: jsonData, encoding: .utf8)
            
            //Save the json string to UserDefaults
            UserDefaults.standard.set(json, forKey: DataManager.PREF_JSON_NAME)
        } catch {
            //Encoding failed. Show error
            print("[TasksManager] Cannot encode JSON!")
            return
        }
    }
    
    func unlockAward(subject: String) {
        let awardToUnlock = Subject.subjects.filter { sub in
            sub.name == subject
        }.first!.awards.first!
        
        //var alreadyUnlocked = false
        for unlockedAward in unlockedAwards {
            if unlockedAward.awardName == awardToUnlock.imageName {
                //alreadyUnlocked = true
                return
            }
        }
        
        unlockedAwards.append(UnlockedAward(awardName: awardToUnlock.imageName, date: Date()))
        
        saveDataToJson()
    }
    
    //Updates the task in the shared list
    func update(task updatedTask: TaskInfo) {
        for index in 0..<tasks.count {
            if tasks[index].id == updatedTask.id {
                tasks[index] = updatedTask
                self.saveDataToJson()
                return
            }
        }
    }
    
    //Delete the task from the shared list
    func delete(task deletedTask: TaskInfo) {
        for index in 0..<tasks.count {
            if tasks[index].id == deletedTask.id {
                tasks.remove(at: index)
                self.saveDataToJson()
                return
            }
        }
    }
    
    func scheduleNotifications() {
        print("[TasksManager] Scheduling notifications")
        let notificationCenter = UNUserNotificationCenter.current()
        notificationCenter.removeAllPendingNotificationRequests()
        for task in tasks {
            if let _ = task.completed {
                continue
            }
            
            guard let taskDate = task.date else {
                continue
            }
            
            if !Calendar.current.isDateInToday(taskDate) {
                continue
            }
            
            let content = UNMutableNotificationContent()
            content.title = "Don't forget your task!"
            content.body = "\(task.subject): \(task.name) is about to expire today!"
            
            
            var dateComponents = Calendar.current.dateComponents([.year, .month, .day], from: taskDate)
            dateComponents.hour = 15
            dateComponents.minute = 30
            let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
            
            // Create the request
            let uuidString = UUID().uuidString
            let request = UNNotificationRequest(identifier: uuidString,
                        content: content, trigger: trigger)

            // Schedule the request with the system.
            
            notificationCenter.add(request) { (error) in
               if error != nil {
                   print("[TasksManager] Cannot add notification trigger")
               }
            }
        }
    }
    
}

struct DataJSON: Codable {
    var tasks: [TaskInfo]
    var unlockedAwards: [UnlockedAward]
}
