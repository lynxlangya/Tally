//
//  JustOneApp.swift
//  JustOne
//
//  Created by 琅邪 on 1/16/26.
//

import SwiftUI
import CoreData

@main
struct JustOneApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
