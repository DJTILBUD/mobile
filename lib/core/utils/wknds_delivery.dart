/// Equipment delivery by WKNDS Events for DJs without their own gear
/// ("non-equipped" DJs).
///
/// Mirrors `web-app/src/helpers/wkndsDelivery.ts` (the parts mobile needs to
/// display budgets and the delivered setup). All amounts incl. moms. Plan:
/// `web-app/documentation/non-equipped-djs-plan.md`. Change both together.
library;

/// What a non-equipped DJ sees deducted from the customer budget, in every
/// zone (2.750 to WKNDS + 1.000 our cut). Mirrors `WKNDS_DELIVERY_DEDUCTION_DKK`.
const wkndsDeliveryDeductionDkk = 3750;

/// The DJ-facing budget for a non-equipped DJ never shows below this.
/// Mirrors `NON_EQUIPPED_DJ_BUDGET_FLOOR_DKK`.
const nonEquippedDjBudgetFloorDkk = 500;

/// The fixed setup delivered to every job, as shown to the DJ. Mirrors
/// `WKNDS_DELIVERED_GEAR`.
const wkndsDeliveredGear = [
  'Pioneer XDJ-RX3',
  '2 x top og 1-2 x bund (RCF)',
  'Festlys',
  'Kabler, stativer og strøm',
];

/// Mirrors `WKNDS_DJ_BRINGS`.
const wkndsDjBrings = 'Medbring kun USB-stik og hovedtelefoner.';

/// Mirrors `isNonEquippedDj`.
bool isNonEquippedDj(String? equipmentStatus) =>
    equipmentStatus == 'non_equipped';

/// Mirrors `deliveryDeductionForDj`: 0 for an equipped DJ.
int deliveryDeductionForDj(String? equipmentStatus) =>
    isNonEquippedDj(equipmentStatus) ? wkndsDeliveryDeductionDkk : 0;
