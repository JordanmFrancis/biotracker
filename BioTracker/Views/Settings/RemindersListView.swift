import SwiftUI
import SwiftData

struct RemindersListView: View {
    @Query(sort: \Reminder.date) private var reminders: [Reminder]
    @Environment(\.modelContext) private var modelContext
    @State private var showAdd = false

    var body: some View {
        List {
            if reminders.isEmpty {
                ContentUnavailableView("No Reminders", systemImage: "bell.slash", description: Text("Tap + to add a reminder for your next blood draw, protocol change, or BP check."))
            }

            ForEach(reminders, id: \.id) { reminder in
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Image(systemName: reminder.reminderType.iconName)
                                .foregroundStyle(reminder.isOverdue ? .red : .blue)
                            Text(reminder.title)
                                .font(.subheadline)
                                .strikethrough(reminder.isCompleted)
                        }
                        Text(reminder.formattedDate)
                            .font(.caption)
                            .foregroundStyle(reminder.isOverdue ? .red : .secondary)
                    }

                    Spacer()

                    Button {
                        reminder.isCompleted.toggle()
                        try? modelContext.save()
                    } label: {
                        Image(systemName: reminder.isCompleted ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(reminder.isCompleted ? .green : .secondary)
                    }
                }
            }
            .onDelete(perform: deleteReminders)
        }
        .navigationTitle("Reminders")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { showAdd = true } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showAdd) {
            ReminderEditView()
        }
    }

    private func deleteReminders(at offsets: IndexSet) {
        for index in offsets {
            let reminder = reminders[index]
            NotificationService.shared.cancelReminder(reminder)
            modelContext.delete(reminder)
        }
        try? modelContext.save()
    }
}

struct ReminderEditView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var type: ReminderType = .bloodDraw
    @State private var date = Date.now.addingTimeInterval(86400 * 7)
    @State private var isRecurring = false

    var body: some View {
        NavigationStack {
            Form {
                TextField("Title", text: $title)

                Picker("Type", selection: $type) {
                    ForEach(ReminderType.allCases, id: \.self) { t in
                        Label(t.label, systemImage: t.iconName).tag(t)
                    }
                }

                DatePicker("Date", selection: $date, displayedComponents: [.date, .hourAndMinute])

                Toggle("Recurring", isOn: $isRecurring)
            }
            .navigationTitle("New Reminder")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        save()
                    }
                    .disabled(title.isEmpty)
                }
            }
        }
    }

    private func save() {
        let reminder = Reminder(title: title, reminderType: type, date: date)
        reminder.isRecurring = isRecurring
        modelContext.insert(reminder)
        try? modelContext.save()

        Task {
            await NotificationService.shared.scheduleReminder(reminder)
        }

        dismiss()
    }
}

#Preview {
    NavigationStack {
        RemindersListView()
    }
    .modelContainer(for: Reminder.self, inMemory: true)
}
