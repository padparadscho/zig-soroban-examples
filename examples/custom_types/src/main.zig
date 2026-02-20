//! Custom Types Contract
//!
//! This contract demonstrates how to define and use custom data structures
//!
//! Build: `zig build custom_types`
//! Deploy: `stellar contract deploy --wasm zig-out/bin/custom_types.wasm --source <account-private-key>`
//! Invoke: `stellar contract invoke --id <contract-id> --source <account-private-key> --network testnet -- increment --incr 10`

const sdk = @import("soroban-sdk");

/// Storage key for the state map in instance storage
const STATE_KEY = sdk.Symbol.fromString("STATE");

/// Map key for the count field within the state map
const COUNT_KEY = sdk.Symbol.fromString("count");

/// Map key for the last_incr field within the state map
const LAST_INCR_KEY = sdk.Symbol.fromString("last_incr");

const CustomTypesContract = struct {
    pub const increment_params = [_][]const u8{"incr"};

    /// Increments the counter by the given value and returns the new count
    ///
    /// # Arguments
    ///
    /// * incr - The amount to increment the counter by
    pub fn increment(incr: sdk.U32Val) sdk.U32Val {
        const incr_u32: u32 = incr.toU32();

        // Read current state from storage, defaulting to count=0 and last_incr=0 if not set
        const state = getStateMap();
        const count_val = state.get(COUNT_KEY);
        const current_count: u32 = sdk.U32Val.fromVal(count_val).toU32();

        const new_count = current_count + incr_u32;

        // Create new state map with updated values
        var new_state = sdk.Map.new();

        new_state.set(COUNT_KEY, sdk.U32Val.fromU32(new_count));
        new_state.set(LAST_INCR_KEY, sdk.U32Val.fromU32(incr_u32));

        // Persist state in instance storage
        sdk.ledger.putContractData(STATE_KEY.toVal(), new_state.toVal(), sdk.StorageType.instance);

        // Extend TTL for instance storage (threshold=50, extend_to=100)
        sdk.ledger.extendCurrentContractInstanceAndCodeTtl(50, 100);

        return sdk.U32Val.fromU32(new_count);
    }

    pub const get_state_params = [_][]const u8{};

    /// Returns the current state as a Map with "count" and "last_incr" fields
    ///
    /// # Arguments
    ///
    /// * None
    pub fn get_state() sdk.Map {
        return getStateMap();
    }
};

// -- Helper functions --

/// Reads the state map from storage or initialize it if not present
fn getStateMap() sdk.Map {
    if (sdk.ledger.getVal(STATE_KEY.toVal(), sdk.StorageType.instance)) |v| {
        return sdk.Map.fromVal(v);
    }

    var initial_state = sdk.Map.new();

    initial_state.set(COUNT_KEY, sdk.U32Val.fromU32(0));
    initial_state.set(LAST_INCR_KEY, sdk.U32Val.fromU32(0));

    return initial_state;
}

comptime {
    _ = sdk.contract.exportContract(CustomTypesContract);
}
