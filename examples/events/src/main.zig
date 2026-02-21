//! Events Contract
//!
//! This contract demonstrates structured event emission
//!
//! Build: `zig build events`
//! Deploy: `stellar contract deploy --wasm zig-out/bin/events.wasm --alias events --source deployer`
//! Invoke: `stellar contract invoke --id events --source user --network testnet -- increment`

const sdk = @import("soroban-sdk");

// Key used to store the counter value
const COUNTER_KEY = sdk.Symbol.fromString("COUNTER");

// Event topic symbols
const TOPIC_COUNTER = sdk.Symbol.fromString("COUNTER");
const TOPIC_INCREMENT = sdk.Symbol.fromString("increment");

const EventsContract = struct {
    pub const increment_params = [_][]const u8{};

    /// Increments the counter by 1, emits an event, and returns the new value
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

        // Emit event with topics ["COUNTER", "increment"] and count as data
        sdk.emit(.{ TOPIC_COUNTER, TOPIC_INCREMENT }, sdk.U32Val.fromU32(new_count));

        return sdk.U32Val.fromU32(new_count);
    }
};

comptime {
    _ = sdk.contract.exportContract(EventsContract);
}
