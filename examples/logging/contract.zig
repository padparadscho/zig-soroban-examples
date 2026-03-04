//! Logging Contract
//!
//! This contract demonstrates how to use the standard Soroban terminal logging to emit debug logs
//!
//! Build: `zig build logging`
//! Deploy: `stellar contract deploy --wasm zig-out/bin/logging.wasm --alias logging --source deployer`
//! Invoke: `stellar contract invoke --id logging --source user --network testnet -- hello --value world`

const sdk = @import("soroban-sdk");

const LoggingContract = struct {
    pub const hello_params = [_][]const u8{"value"};

    /// Logs a greeting with the provided value
    ///
    /// # Arguments
    ///
    /// * `value` - A Symbol that will be included in the log message
    pub fn hello(value: sdk.Symbol) sdk.Void {
        sdk.log("Hello {}", .{value});

        return sdk.Void.VOID;
    }
};

comptime {
    _ = sdk.contract.exportContract(LoggingContract);
}
