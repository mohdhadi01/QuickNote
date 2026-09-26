import SwiftUI

/// Sidebar sections (spec §19).
struct SidebarView: View {
    @Binding var selection: NoteFilter

    var body: some View {
        List(selection: $selection) {
            Section {
                ForEach(NoteFilter.allCases) { filter in
                    Label(filter.title, systemImage: filter.symbolName)
                        .tag(filter)
                }
            }
        }
        .listStyle(.sidebar)
        .navigationTitle("QuickNote")
        .accessibilityLabel("Sections")
    }
}
