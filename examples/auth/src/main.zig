//! Auth Contract
//!
//! This contract demonstrates authentication
//!
//! Build: `zig build auth`
//! Deploy: `stellar contract deploy --wasm zig-out/bin/auth.wasm --source <account-private-key>`
//! Invoke: `stellar contract invoke --id <contract-id> --source <account-private-key> --network testnet -- increment --user <account-public-key> --value 10`

const sdk = @import("soroban-sdk");

const AuthContract = struct {
    pub const increment_params = [_][]const u8{ "user", "value" };

    /// Increments the counter by a given value after authenticating,
    /// fails if user is not authenticated
    ///
    /// # Arguments
    ///
    /// * `user` - The Address of the user whose counter to increment
    /// * `value` - The u32 value to add to the counter
    pub fn increment(user: sdk.Address, value: sdk.U32Val) sdk.U32Val {
        // Require that the user is authenticated to invoke this function
        user.requireAuth();

        const count = readCounter(user);
        const new_count = count + value.toU32();

        writeCounter(user, new_count);

        return sdk.val.U32Val.fromU32(new_count);
    }
};

comptime {
    _ = sdk.contract.exportContract(AuthContract);
}

// -- Helper functions --

/// Base key used for constructing storage keys for user counters
const BASE_KEY = sdk.Symbol.fromString("COUNTER");

/// Constructs the storage key combining the base key with the user address
/// ["COUNTER", user_address]
fn makeKey(user: sdk.Address) sdk.Val {
    return sdk.asVal(sdk.Vec.from(.{ BASE_KEY, user }));
}

/// Writes the counter value for a given user to persistent storage
fn writeCounter(user: sdk.Address, count: u32) void {
    const key = makeKey(user);

    sdk.ledger.putContractData(key, sdk.val.U32Val.fromU32(count).toVal(), sdk.StorageType.persistent);
}

/// Reads the counter value for a given user from persistent storage,
/// returns 0 if not set
fn readCounter(user: sdk.Address) u32 {
    const key = makeKey(user);
    const val = sdk.ledger.getVal(key, sdk.StorageType.persistent);

    if (val) |v| {
        return sdk.val.U32Val.fromVal(v).toU32();
    }

    return 0;
}
