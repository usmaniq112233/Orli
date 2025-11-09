//
//  ScheduleMessage.swift
//  Orli
//
//  Created by mohammad ali panhwar on 27/06/2025.
//
import SwiftUI

struct ScheduleMessageView: View {
    let isSubscribed: Bool
    @Binding var selectedDate: Date?
    @Binding var repeatOption: String
    @Binding var selectedTimeZone: TimeZone
    
    @State private var tempDate: Date = Date()
    @Environment(\.dismiss) var dismiss

    let repeatOptions = ["None", "Daily", "Weekly", "Monthly"]

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Delivery Date")) {
                    DatePicker("Select Date & Time", selection: $tempDate, in: Date()...)
                }

                Section(header: Text("Repeat")) {
                    if isSubscribed {
                        Picker("Repeat", selection: $repeatOption) {
                            ForEach(repeatOptions, id: \.self) { Text($0) }
                        }
                    } else {
                        LockedRow(label: "Repeat Scheduling")
                    }
                }

                Section(header: Text("Time Zone")) {
                    if isSubscribed {
                        // Replace this:
                        // Text(selectedTimeZone.identifier)

                        // With this:
                        Picker("Select Time Zone", selection: $selectedTimeZone) {
                            ForEach(TimeZone.knownTimeZoneIdentifiers, id: \.self) { id in
                                let tz = TimeZone(identifier: id) ?? .current
                                Text(tz.identifier)
                                    .tag(tz)
                            }
                        }
                    } else {
                        LockedRow(label: "Custom Time Zones")
                    }
                }


                Section {
                    Button(action: {
                        selectedDate = tempDate
                        dismiss()
                    }) {
                        Text("Confirm Schedule")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color("Button"))
                            .foregroundColor(.white)
                            .font(.headline)
                            .cornerRadius(12)
                    }
                }
            }
            .navigationTitle("Schedule Message")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                    // If parent already has a date, use it
                    if let existing = selectedDate {
                    tempDate = existing
                }
            }
        }
    }
}

struct LockedRow: View {
    let label: String
    var body: some View {
        HStack {
            Image(systemName: "lock.fill")
                .foregroundColor(.gray)
            Text(label)
                .foregroundColor(.gray)
        }
        .blur(radius: 0.3)
        .contentShape(Rectangle())
    }
}
