//! TTL Contract
//!
//! This contract demonstrates how to manage TTL (Time-To-Live) for contract data
//!
//! Build: `zig build ttl`
//! Deploy: `stellar contract deploy --wasm zig-out/bin/ttl.wasm --alias ttl --source deployer`
//! Invoke setup:
//!     - 'setup': `stellar contract invoke --id ttl --source user --network testnet -- setup`
//!     - 'extend_persistent': `stellar contract invoke --id ttl --source user --network testnet -- extend_persistent`
//!     - 'extend_instance': `stellar contract invoke --id ttl --source user --network testnet -- extend_instance`
//!     - 'extend_temporary': `stellar contract invoke --id ttl --source user --network testnet -- extend_temporary`

const sdk = @import("soroban-sdk");

/// Storage key for TTL demo entries
const TTL_KEY = sdk.Symbol.fromString("TTL");

/// Custom error codes
const Error = enum(u32) {
    PersistentEntryNotFound = 1,
    InstanceEntryNotFound = 2,
    TemporaryEntryNotFound = 3,
};

const TtlContract = struct {
    pub const setup_params = [_][]const u8{};

    /// Creates entries in each storage type (persistent, instance, temporary)
    ///
    /// # Arguments
    ///
    /// * None
    pub fn setup() sdk.Void {
        sdk.ledger.putU32(TTL_KEY, 0, sdk.StorageType.persistent);
        sdk.ledger.putU32(TTL_KEY, 1, sdk.StorageType.instance);
        sdk.ledger.putU32(TTL_KEY, 2, sdk.StorageType.temporary);

        return sdk.Void.VOID;
    }

    pub const extend_persistent_params = [_][]const u8{};

    /// Extends the TTL of the persistent storage entry
    ///
    /// # Arguments
    ///
    /// * None
    pub fn extend_persistent() sdk.Void {
        // Verify entry exists
        _ = sdk.ledger.getU32(TTL_KEY, sdk.StorageType.persistent) orelse {
            const error_val = sdk.val.Error.fromParts(0, @intFromEnum(Error.PersistentEntryNotFound));
            sdk.ledger.failWithError(error_val);
        };

        // threshold=1000 (triggers if TTL < 1000), extend_to=5000
        sdk.ledger.extendContractDataTtl(sdk.val.asVal(TTL_KEY), sdk.StorageType.persistent, 1000, 5000);

        return sdk.Void.VOID;
    }

    pub const extend_instance_params = [_][]const u8{};

    /// Extends the TTL of the instance storage entry
    ///
    /// # Arguments
    ///
    /// * None
    pub fn extend_instance() sdk.Void {
        // Verify instance entry exists
        _ = sdk.ledger.getU32(TTL_KEY, sdk.StorageType.instance) orelse {
            const error_val = sdk.val.Error.fromParts(0, @intFromEnum(Error.InstanceEntryNotFound));
            sdk.ledger.failWithError(error_val);
        };

        // threshold=2000 (triggers if TTL < 2000), extend_to=10000
        sdk.ledger.extendCurrentContractInstanceAndCodeTtl(2000, 10000);

        return sdk.Void.VOID;
    }

    pub const extend_temporary_params = [_][]const u8{};

    /// Extends the TTL of the temporary storage entry
    ///
    /// # Arguments
    ///
    /// * None
    pub fn extend_temporary() sdk.Void {
        // Verify entry exists
        _ = sdk.ledger.getU32(TTL_KEY, sdk.StorageType.temporary) orelse {
            const error_val = sdk.val.Error.fromParts(0, @intFromEnum(Error.TemporaryEntryNotFound));
            sdk.ledger.failWithError(error_val);
        };

        // threshold=3000 (triggers if TTL < 3000), extend_to=7000
        sdk.ledger.extendContractDataTtl(sdk.val.asVal(TTL_KEY), sdk.StorageType.temporary, 3000, 7000);

        return sdk.Void.VOID;
    }
};

comptime {
    _ = sdk.contract.exportContract(TtlContract);
}
