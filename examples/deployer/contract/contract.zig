//! Simple Contract
//!
//! This contract stores a u32 value passed via constructor
//!
//! Build: `zig build simple_contract`
//! Deploy: Deployed via the deployer factory contract

const sdk = @import("soroban-sdk");

/// Storage key for the stored value in instance storage
const VALUE = sdk.Symbol.fromString("Value");

const SimpleContract = struct {
    pub const __constructor_params = [_][]const u8{"value"};

    /// Construct the contract with an initial value
    ///
    /// Arguments:
    ///
    /// * `initial_value` - The initial `u32` value to store in instance storage
    pub fn __constructor(initial_value: sdk.U32Val) void {
        sdk.ledger.putContractData(VALUE.toVal(), initial_value.toVal(), .instance);
    }

    /// Get the stored `u32` value from instance storage
    ///
    /// Arguments:
    ///
    /// * None
    pub fn value() sdk.U32Val {
        const val = sdk.ledger.getContractData(VALUE.toVal(), .instance);
        return sdk.U32Val.fromVal(val);
    }
};

comptime {
    _ = sdk.contract.exportContract(SimpleContract);
}
