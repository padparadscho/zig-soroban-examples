//! Token Contract: Storage Types Module

const sdk = @import("soroban-sdk");

/// Number of ledgers in a day, ~5 seconds per ledger
pub const DAY_IN_LEDGERS: u32 = 17280;

/// Instance storage TTL
pub const INSTANCE_BUMP_AMOUNT: u32 = 7 * DAY_IN_LEDGERS;
pub const INSTANCE_LIFETIME_THRESHOLD: u32 = INSTANCE_BUMP_AMOUNT - DAY_IN_LEDGERS;

/// Balance storage TTL
pub const BALANCE_BUMP_AMOUNT: u32 = 30 * DAY_IN_LEDGERS;
pub const BALANCE_LIFETIME_THRESHOLD: u32 = BALANCE_BUMP_AMOUNT - DAY_IN_LEDGERS;

// Storage keys
const ADMIN_KEY = sdk.Symbol.fromString("ADMIN");
const DEC_KEY = sdk.Symbol.fromString("DEC");
const NAME_KEY = sdk.Symbol.fromString("NAME");
const SYM_KEY = sdk.Symbol.fromString("SYMBOL");
const BAL_TAG = sdk.Symbol.fromString("BAL");
const ALLOW_TAG = sdk.Symbol.fromString("ALLOW");

/// Returns storage key for admin address
pub fn adminKey() sdk.Val {
    return sdk.asVal(ADMIN_KEY);
}

/// Returns storage key for decimals
pub fn decimalsKey() sdk.Val {
    return sdk.asVal(DEC_KEY);
}

/// Returns storage key for token name
pub fn nameKey() sdk.Val {
    return sdk.asVal(NAME_KEY);
}

/// Returns storage key for token symbol
pub fn symbolKey() sdk.Val {
    return sdk.asVal(SYM_KEY);
}

/// Returns storage key for balance entry
pub fn balanceKey(addr: sdk.Address) sdk.Val {
    return sdk.asVal(sdk.Vec.from(.{ BAL_TAG, addr }));
}

/// Returns storage key for allowance entry
pub fn allowanceKey(from: sdk.Address, spender: sdk.Address) sdk.Val {
    return sdk.asVal(sdk.Vec.from(.{ ALLOW_TAG, from, spender }));
}

/// Allowance data stored in temporary storage
pub const AllowanceData = struct {
    amount: i128,
    expiration_ledger: u32,
};
