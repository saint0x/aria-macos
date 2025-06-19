"use client"
// Accordion and Button are no longer needed from here if the accordion is removed.
// However, Button might still be used for the text links if we decide to style them as such.
// For now, assuming text links are simple <button> or <a> tags.

export function BillingView() {
  // Static data for the current "Pro Plan"
  const staticCurrentPlanName = "Pro Plan"
  // const staticCurrentPlanPrice = "$20/mo"; // Kept for reference if needed elsewhere
  const renewalDate = new Date()
  renewalDate.setMonth(renewalDate.getMonth() + 1)
  const availableCredits = 170

  // handleStripeButtonClick is removed as the button is gone.

  return (
    <div className="p-1 animate-slide-up-fade space-y-2">
      {/* Current Plan Static Display */}
      <div className="rounded-xl bg-white/20 dark:bg-neutral-700/20 shadow-apple-sm p-3.5 space-y-3">
        <div className="grid grid-cols-3 gap-3 text-center">
          <div>
            <p className="text-xs text-neutral-600 dark:text-neutral-400">Current Plan</p>
            <p className="text-sm font-medium text-neutral-800 dark:text-neutral-100 mt-0.5">{staticCurrentPlanName}</p>
          </div>
          <div>
            <p className="text-xs text-neutral-600 dark:text-neutral-400">Renews on</p>
            <p className="text-sm font-medium text-neutral-800 dark:text-neutral-100 mt-0.5">
              {renewalDate.toLocaleDateString("en-US", { month: "short", day: "numeric", year: "numeric" })}
            </p>
          </div>
          <div>
            <p className="text-xs text-neutral-600 dark:text-neutral-400">Available Credits</p>
            <p className="text-sm font-medium text-neutral-800 dark:text-neutral-100 mt-0.5">{availableCredits}</p>
          </div>
        </div>
        <div className="flex justify-center items-center gap-4 pt-2">
          <button className="text-xs text-neutral-700 dark:text-neutral-300 hover:text-neutral-900 dark:hover:text-neutral-100 transition-colors">
            Add Credits
          </button>
          <span className="text-neutral-400 dark:text-neutral-600">|</span>
          <button className="text-xs text-neutral-700 dark:text-neutral-300 hover:text-neutral-900 dark:hover:text-neutral-100 transition-colors">
            Upgrade Plan
          </button>
          <span className="text-neutral-400 dark:text-neutral-600">|</span>
          <button className="text-xs text-red-600 dark:text-red-500 hover:text-red-700 dark:hover:text-red-400 transition-colors">
            Cancel Plan
          </button>
        </div>
      </div>

      {/* "Update Plan" Accordion and "Billing managed by Stripe" paragraph are removed. */}
    </div>
  )
}
