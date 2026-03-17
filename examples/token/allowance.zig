//! Token Contract: Allowance Module

const sdk = @import("soroban-sdk");

const storage = @import("storage_types.zig");

/// Reads allowance data, returns zero if expired or not found
pub fn read(from: sdk.Address, spender: sdk.Address) storage.AllowanceData {
    const key = storage.allowanceKey(from, spender);

    if (sdk.ledger.hasContractData(key, sdk.StorageType.temporary)) {
        const data = sdk.Vec.fromVal(sdk.ledger.getContractData(key, sdk.StorageType.temporary));
        const amount = sdk.int.i128FromVal(sdk.I128Val.fromVal(data.get(0)));
        const expiration_ledger = sdk.U32Val.fromVal(data.get(1)).toU32();

        if (expiration_ledger < sdk.ledger.getLedgerSequence()) {
            return .{ .amount = 0, .expiration_ledger = expiration_ledger };
        }
        return .{ .amount = amount, .expiration_ledger = expiration_ledger };
    }
    return .{ .amount = 0, .expiration_ledger = 0 };
}

/// Writes allowance data to temporary storage
pub fn write(from: sdk.Address, spender: sdk.Address, amount: i128, expiration_ledger: u32) void {
    const key = storage.allowanceKey(from, spender);
    const ledger_seq = sdk.ledger.getLedgerSequence();

    if (amount > 0 and expiration_ledger >= ledger_seq) {
        const data = sdk.Vec.from(.{ sdk.int.i128ToVal(amount), sdk.U32Val.fromU32(expiration_ledger) });

        sdk.ledger.putContractData(key, sdk.asVal(data), sdk.StorageType.temporary);

        const duration = expiration_ledger - ledger_seq;
        const max_live_until = sdk.ledger.getMaxLiveUntilLedger();
        const live_until = @min(expiration_ledger, max_live_until);

        if (live_until > ledger_seq) {
            sdk.ledger.extendContractDataTtl(key, sdk.StorageType.temporary, duration, live_until - ledger_seq);
        }
    } else if (sdk.ledger.hasContractData(key, sdk.StorageType.temporary)) {
        sdk.ledger.delContractData(key, sdk.StorageType.temporary);
    }
}

/// Spends from allowance
pub fn spend(from: sdk.Address, spender: sdk.Address, amount: i128) void {
    const data = read(from, spender);

    if (data.amount < amount) {
        sdk.failContract(1);
    }
    write(from, spender, data.amount - amount, data.expiration_ledger);
}
