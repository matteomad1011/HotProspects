//
//  ProspectView.swift
//  HotProspects
//
//  Created by Matteo Cavallo on 22/07/21.
//

import SwiftUI
import CodeScanner
import UserNotifications

enum FilterType {
    case none, contacted, uncontacted
}

struct ProspectView: View {
    @EnvironmentObject var prospects: Prospects
    var filter: FilterType
    
    @State private var isShowingScanner = false
    
    
    var title: String {
        switch filter {
        case .none:
            return "Everyone"
        case .contacted:
            return "Contacted people"
        case .uncontacted:
            return "Uncontacted people"
        }
    }
    
    var filteredProspects: [Prospect] {
        switch filter {
        case .none:
            return prospects.people
        case .contacted:
            return prospects.people.filter { $0.isContacted }
        case .uncontacted:
            return prospects.people.filter { !$0.isContacted }
        }
    }
    
    var body: some View {
        NavigationView{
            List{
                ForEach(filteredProspects){prospect in
                    VStack(alignment: .leading){
                        Text(prospect.name)
                            .font(.headline)
                        Text(prospect.emailAddress)
                            .foregroundColor(.secondary)
                    }
                    .contextMenu{
                        Button(prospect.isContacted ? "Mark Uncontacted" : "Mark Contacted"){
                            prospects.toggle(prospect)
                        }
                        if !prospect.isContacted {
                            Button("Remind me"){
                                addNotification(for: prospect)
                            }
                        }
                    }
                }
            }
                .navigationBarTitle(title)
                .navigationBarItems(trailing: Button(action: {
                    self.isShowingScanner = true
                }) {
                    Image(systemName: "qrcode.viewfinder")
                    Text("Scan")
                })
            .sheet(isPresented: $isShowingScanner){
                CodeScannerView(codeTypes: [.qr], simulatedData: "Matteo Cavallo\nm.cavallo1011@gmail.com", completion: handleScan)
            }
        }
    }
    
    func handleScan(result: Result<String, CodeScannerView.ScanError>){
        self.isShowingScanner = false
        switch result {
        case .success(let code):
            let details = code.components(separatedBy: "\n")
            guard details.count == 2 else {return}
            
            let person = Prospect()
            person.name = details[0]
            person.emailAddress = details[1]
            
            prospects.add(person)
        case .failure(let error):
            print("Scanning failed")
        }
    }
    
    func addNotification(for prospect: Prospect){
        let center = UNUserNotificationCenter.current()
        
        let addRequest = {
            let content = UNMutableNotificationContent()
            content.title = "Contact \(prospect.name)"
            content.subtitle = prospect.emailAddress
            content.sound = .default
            
            var components = DateComponents()
            components.hour = 9
            
            //let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
            
            let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
            
            center.add(request)
        }
        
        center.getNotificationSettings { settings in
            if settings.authorizationStatus == .authorized {
                addRequest()
            } else {
                center.requestAuthorization(options: [.sound, .alert, .badge]){ granted, error in
                    if granted {
                        addRequest()
                    } else {
                        print("Please give permission to notification")
                    }
                }
            }
        }
    }
}

struct ProspectView_Previews: PreviewProvider {
    static var previews: some View {
        ProspectView(filter: .none)
    }
}
