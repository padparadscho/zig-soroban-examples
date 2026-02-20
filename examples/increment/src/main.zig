//! Increment Contract
//!
//! This contract demonstrates a simple counter that can be incremented
//!
//! Build: `zig build increment`
//! Deploy: `stellar contract deploy --wasm zig-out/bin/increment.wasm --source <account-private-key>`
//! Invoke: `stellar contract invoke --id <contract-id> --source <account-private-key> --network testnet -- increment`

const sdk = @import("soroban-sdk");

// Key used to store the counter value
const COUNTER_KEY = sdk.Symbol.fromString("COUNTER");

const IncrementContract = struct {
    pub const increment_params = [_][]const u8{};

    /// Increments the counter by 1 and returns the new value
    ///
    /// # Arguments
    ///
    /// * None
    pub fn increment() sdk.U32Val {
        // Read the current count from instance storage, defaulting to 0
        const count: u32 = sdk.ledger.getU32(COUNTER_KEY, sdk.StorageType.instance) orelse 0;

        const new_count = count + 1;

        // Store the new count in instance storage
        sdk.ledger.putU32(COUNTER_KEY, new_count, sdk.StorageType.instance);

        // Extend TTL for instance storage (threshold=50, extend_to=100)
        sdk.ledger.extendCurrentContractInstanceAndCodeTtl(50, 100);

        return sdk.U32Val.fromU32(new_count);
    }
};

comptime {
    _ = sdk.contract.exportContract(IncrementContract);
}
