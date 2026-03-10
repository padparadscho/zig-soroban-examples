//! Contract A
//!
//! This contract provides a simple addition function to be called by other contracts
//!
//! Build: `zig build cross_contract_a`
//! Deploy: `stellar contract deploy --wasm zig-out/bin/cross_contract_a.wasm --alias cross_contract_a --source deployer`
//! Invoke: `stellar contract invoke --id cross_contract_a --source user --network testnet -- add --x 5 --y 3`

const sdk = @import("soroban-sdk");

const ContractA = struct {
    pub const add_params = [_][]const u8{ "x", "y" };

    /// Adds two u32 values and returns the result
    ///
    /// # Arguments
    ///
    /// * x - First operand
    /// * y - Second operand
    pub fn add(x: sdk.U32Val, y: sdk.U32Val) sdk.U32Val {
        const x_val = x.toU32();
        const y_val = y.toU32();

        // Checked addition to prevent overflow
        const result = std.math.add(u32, x_val, y_val) catch {
            sdk.failContract(1);
        };

        return sdk.U32Val.fromU32(result);
    }
};

const std = @import("std");

comptime {
    _ = sdk.contract.exportContract(ContractA);
}
