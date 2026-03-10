//! Contract B
//!
//! This contract demonstrates how to call contract_a via cross-contract calls
//!
//! Build: `zig build cross_contract_b`
//! Deploy: `stellar contract deploy --wasm zig-out/bin/cross_contract_b.wasm --alias cross_contract_b --source deployer`
//! Invoke: `stellar contract invoke --id cross_contract_b --source user --network testnet -- add_with --contract cross_contract_a --x 5 --y 3`

const sdk = @import("soroban-sdk");

// Function name symbol for calling contract_a
const ADD = sdk.Symbol.fromString("add");

const ContractB = struct {
    pub const add_with_params = [_][]const u8{ "contract", "x", "y" };

    /// Calls the 'add' function on contract_a and returns the result
    ///
    /// # Arguments
    ///
    /// * contract - The address of contract_a
    /// * x - First operand to pass to contract_a
    /// * y - Second operand to pass to contract_a
    pub fn add_with(contract: sdk.Address, x: sdk.U32Val, y: sdk.U32Val) sdk.U32Val {
        const result = sdk.callWithArgs(contract, ADD, .{ x, y });

        return sdk.U32Val.fromVal(result);
    }
};

comptime {
    _ = sdk.contract.exportContract(ContractB);
}
