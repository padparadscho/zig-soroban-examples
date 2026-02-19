//! Errors Contract
//!
//! This contract demonstrates how to define and handle custom errors
//!
//! Build: `zig build errors`
//! Deploy: `stellar contract deploy --wasm zig-out/bin/errors.wasm --source <account-private-key>`
//! Invoke: `stellar contract invoke --id <contract-id> --source <account-private-key> --network testnet -- increment`

const sdk = @import("soroban-sdk");

// Key used to store the counter value
const COUNTER_KEY = sdk.Symbol.fromString("COUNTER");

/// Maximum allowed counter value
const MAX_COUNT: u32 = 5;

/// Custom error code
const Error = enum(u32) {
    LimitReached = 1,
};

const ErrorsContract = struct {
    pub const increment_params = [_][]const u8{};

    /// Increments the counter by 1 and returns the new value if the counter has not
    /// reached the maximum allowed value, otherwise fails with a `LimitReached` error
    ///
    /// # Arguments
    ///
    /// * None
    pub fn increment() sdk.U32Val {
        // Read the current count from instance storage, defaulting to 0
        const count: u32 = sdk.ledger.getU32(COUNTER_KEY, sdk.StorageType.instance) orelse 0;

        // Check if the counter has reached the maximum allowed value
        if (count >= MAX_COUNT) {
            // Create error with type=0 (SCE_CONTRACT in XDR spec)
            // NOTE: SCErrorType.Contract is set to 4, but the XDR spec defines SCE_CONTRACT = 0, so we pass 0 directly
            const error_val = sdk.val.Error.fromParts(0, @intFromEnum(Error.LimitReached));
            sdk.ledger.failWithError(error_val);
        }

        const new_count = count + 1;

        // Store the new count in instance storage
        sdk.ledger.putU32(COUNTER_KEY, new_count, sdk.StorageType.instance);

        // Extend TTL for instance storage (threshold=50, extend_to=100)
        sdk.ledger.extendCurrentContractInstanceAndCodeTtl(50, 100);

        return sdk.U32Val.fromU32(new_count);
    }
};

comptime {
    _ = sdk.contract.exportContract(ErrorsContract);
}
