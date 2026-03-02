//! Hello World Contract
//!
//! This contract demonstrates the basic structure of a Soroban contract
//!
//! Build: `zig build hello`
//! Deploy: `stellar contract deploy --wasm zig-out/bin/hello.wasm --alias hello --source deployer`
//! Invoke: `stellar contract invoke --id hello --source user --network testnet -- hello --to world`

const sdk = @import("soroban-sdk");

const HelloContract = struct {
    pub const hello_params = [_][]const u8{"to"};

    /// Takes a Symbol and returns a Vec containing ["Hello", to]
    ///
    /// # Arguments
    ///
    /// * `to` - A Symbol representing the name to greet
    pub fn hello(to: sdk.Symbol) sdk.Vec {
        return sdk.Vec.from(.{ sdk.Symbol.fromString("Hello"), to });
    }
};

comptime {
    _ = sdk.contract.exportContract(HelloContract);
}
