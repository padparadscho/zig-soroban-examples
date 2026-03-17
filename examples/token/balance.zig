//! Token Contract: Balance Module

const sdk = @import("soroban-sdk");

const storage = @import("storage_types.zig");

/// Reads balance from persistent storage with TTL extension
pub fn read(id: sdk.Address) i128 {
    const key = storage.balanceKey(id);

    if (sdk.ledger.getI128(key, sdk.StorageType.persistent)) |balance| {
        sdk.ledger.extendContractDataTtl(
            key,
            sdk.StorageType.persistent,
            storage.BALANCE_LIFETIME_THRESHOLD,
            storage.BALANCE_BUMP_AMOUNT,
        );
        return balance;
    }
    return 0;
}

/// Writes balance to persistent storage with TTL extension
pub fn write(id: sdk.Address, amount: i128) void {
    const key = storage.balanceKey(id);

    sdk.ledger.putI128(key, amount, sdk.StorageType.persistent);
    sdk.ledger.extendContractDataTtl(
        key,
        sdk.StorageType.persistent,
        storage.BALANCE_LIFETIME_THRESHOLD,
        storage.BALANCE_BUMP_AMOUNT,
    );
}

/// Adds amount to balance
pub fn receive(id: sdk.Address, amount: i128) void {
    const current = read(id);

    write(id, current + amount);
}

/// Subtracts amount from balance, fails if insufficient
pub fn spend(id: sdk.Address, amount: i128) void {
    const current = read(id);

    if (current < amount) {
        sdk.failContract(4);
    }
    write(id, current - amount);
}
