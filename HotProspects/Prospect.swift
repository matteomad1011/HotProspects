//
//  Prospect.swift
//  HotProspects
//
//  Created by Matteo Cavallo on 23/07/21.
//

import Foundation

class Prospect: Identifiable, Codable {
    let id = UUID()
    var name = "Anonymous"
    var emailAddress = ""
    fileprivate(set) var isContacted = false
}

class Prospects: ObservableObject {
    @Published fileprivate(set) var people: [Prospect]
    
    static let saveKey = "SavedData"
    
    init() {
        if let data = UserDefaults.standard.data(forKey: Self.saveKey){
            if let decoded = try? JSONDecoder().decode([Prospect].self, from: data){
                self.people = decoded
                return
            }
        }
        
        self.people = []
    }
    
    func add(_ prospect: Prospect){
        self.people.append(prospect)
        save()
    }
    
    private func save(){
        if let data = try? JSONEncoder().encode(people){
            UserDefaults.standard.setValue(data, forKey: Self.saveKey)
        }
    }
    
    func toggle(_ prospect: Prospect){
        objectWillChange.send()
        prospect.isContacted.toggle()
        self.save()
    }
}
