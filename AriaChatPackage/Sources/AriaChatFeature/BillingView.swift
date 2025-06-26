import SwiftUI

// MARK: - Billing View matching SWIFT2.md spec exactly
struct BillingView: View {
    @Environment(\.colorScheme) var colorScheme
    
    // Static data as per SWIFT2.md
    let planName = "Pro Plan"
    let availableCredits = 170
    
    var renewalDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        let nextMonth = Calendar.current.date(byAdding: .month, value: 1, to: Date()) ?? Date()
        return formatter.string(from: nextMonth)
    }
    
    var body: some View {
        VStack(spacing: 8) { // space-y-2
            // Current Plan Static Display Card
            VStack(spacing: 12) { // space-y-3
                // Grid Section - 3 columns
                HStack(spacing: 12) { // gap-3
                    // Current Plan
                    VStack(alignment: .center) {
                        Text("Current Plan")
                            .font(.textXS) // text-xs
                            .foregroundColor(Color.textSecondary(for: colorScheme)) // text-neutral-600 dark:text-neutral-400
                        
                        Text(planName)
                            .font(.textSM(.medium)) // text-sm font-medium
                            .foregroundColor(Color.textPrimary(for: colorScheme)) // text-neutral-800 dark:text-neutral-100
                            .padding(.top, 2) // mt-0.5
                    }
                    .frame(maxWidth: .infinity)
                    
                    // Renews On
                    VStack(alignment: .center) {
                        Text("Renews On")
                            .font(.textXS)
                            .foregroundColor(Color.textSecondary(for: colorScheme))
                        
                        Text(renewalDate)
                            .font(.textSM(.medium))
                            .foregroundColor(Color.textPrimary(for: colorScheme))
                            .padding(.top, 2)
                    }
                    .frame(maxWidth: .infinity)
                    
                    // Available Credits
                    VStack(alignment: .center) {
                        Text("Available Credits")
                            .font(.textXS)
                            .foregroundColor(Color.textSecondary(for: colorScheme))
                        
                        Text("\(availableCredits)")
                            .font(.textSM(.medium))
                            .foregroundColor(Color.textPrimary(for: colorScheme))
                            .padding(.top, 2)
                    }
                    .frame(maxWidth: .infinity)
                }
                
                // Links Section
                HStack(spacing: 16) { // gap-4
                    Button(action: {}) {
                        Text("Add Credits")
                            .font(.textXS)
                            .foregroundColor(Color.textSecondary(for: colorScheme))
                    }
                    .buttonStyle(.plain)
                    .hoverHighlight()
                    
                    Text("|")
                        .foregroundColor(Color(red: 163/255, green: 163/255, blue: 163/255)) // neutral-400
                    
                    Button(action: {}) {
                        Text("Manage Plan")
                            .font(.textXS)
                            .foregroundColor(Color.textSecondary(for: colorScheme))
                    }
                    .buttonStyle(.plain)
                    .hoverHighlight()
                    
                    Text("|")
                        .foregroundColor(Color(red: 163/255, green: 163/255, blue: 163/255))
                    
                    Button(action: {}) {
                        Text("Cancel Plan")
                            .font(.textXS)
                            .foregroundColor(Color(red: 220/255, green: 38/255, blue: 38/255)) // text-red-600
                    }
                    .buttonStyle(.plain)
                    .hoverHighlight()
                }
                .padding(.top, 8) // pt-2
            }
            .padding(14) // p-3.5
            .background(
                RoundedRectangle(cornerRadius: 16) // rounded-xl
                    .fill(Color.inputBackground(for: colorScheme)) // bg-white/20 dark:bg-neutral-700/20
            )
            .appleShadowSmall() // shadow-apple-sm
        }
        .padding(4) // p-1
        .slideUpFade(isVisible: true) // animate-slide-up-fade
    }
}