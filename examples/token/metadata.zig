//! Token Contract: Metadata Module

const sdk = @import("soroban-sdk");

const storage = @import("storage_types.zig");

/// Reads decimals from instance storage with TTL extension
pub fn readDecimals() u32 {
    sdk.ledger.extendCurrentContractInstanceAndCodeTtl(
        storage.INSTANCE_LIFETIME_THRESHOLD,
        storage.INSTANCE_BUMP_AMOUNT,
    );
    return sdk.ledger.getU32(storage.decimalsKey(), sdk.StorageType.instance) orelse 0;
}

/// Writes decimals to instance storage
pub fn writeDecimals(d: u32) void {
    sdk.ledger.putU32(storage.decimalsKey(), d, sdk.StorageType.instance);
}

/// Reads token name from instance storage with TTL extension
pub fn readName() sdk.String {
    sdk.ledger.extendCurrentContractInstanceAndCodeTtl(
        storage.INSTANCE_LIFETIME_THRESHOLD,
        storage.INSTANCE_BUMP_AMOUNT,
    );
    return sdk.String.fromVal(sdk.ledger.getContractData(storage.nameKey(), sdk.StorageType.instance));
}

/// Writes token name to instance storage
pub fn writeName(n: sdk.String) void {
    sdk.ledger.putContractData(storage.nameKey(), n.toVal(), sdk.StorageType.instance);
}

/// Reads token symbol from instance storage with TTL extension
pub fn readSymbol() sdk.String {
    sdk.ledger.extendCurrentContractInstanceAndCodeTtl(
        storage.INSTANCE_LIFETIME_THRESHOLD,
        storage.INSTANCE_BUMP_AMOUNT,
    );
    return sdk.String.fromVal(sdk.ledger.getContractData(storage.symbolKey(), sdk.StorageType.instance));
}

/// Writes token symbol to instance storage
pub fn writeSymbol(s: sdk.String) void {
    sdk.ledger.putContractData(storage.symbolKey(), s.toVal(), sdk.StorageType.instance);
}
