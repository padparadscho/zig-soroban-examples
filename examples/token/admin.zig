//! Token Contract: Admin Module

const sdk = @import("soroban-sdk");

const storage = @import("storage_types.zig");

/// Reads admin address from instance storage with TTL extension
pub fn read() sdk.Address {
    sdk.ledger.extendCurrentContractInstanceAndCodeTtl(
        storage.INSTANCE_LIFETIME_THRESHOLD,
        storage.INSTANCE_BUMP_AMOUNT,
    );
    return sdk.Address.fromVal(sdk.ledger.getContractData(storage.adminKey(), sdk.StorageType.instance));
}

/// Writes admin address to instance storage
pub fn write(admin: sdk.Address) void {
    sdk.ledger.putContractData(storage.adminKey(), admin.toVal(), sdk.StorageType.instance);
}
