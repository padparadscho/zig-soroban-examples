//! Alloc Contract
//!
//! This contract demonstrates dynamic allocation of Soroban Vec type
//!
//! Build: `zig build alloc`
//! Deploy: `stellar contract deploy --wasm zig-out/bin/alloc.wasm --alias alloc --source deployer`
//! Invoke: `stellar contract invoke --id alloc --source user --network testnet -- sum --count <u32>`

const sdk = @import("soroban-sdk");

const AllocContract = struct {
    pub const sum_params = [_][]const u8{"count"};

    /// Allocates a vector holding values (0..count), then computes and returns their sum
    ///
    /// # Arguments
    ///
    /// * `count` - The number of elements to allocate in the vector
    pub fn sum(count: sdk.U32Val) sdk.U32Val {
        const count_u32 = sdk.U32Val.fromVal(count.toVal()).toU32();

        var v = sdk.Vec.new();
        var i: u32 = 0;
        while (i < count_u32) : (i += 1) {
            v.pushBack(sdk.U32Val.fromU32(i));
        }

        var total: u32 = 0;
        var j: u32 = 0;
        while (j < v.len()) : (j += 1) {
            const elem = v.get(j);
            const elem_u32 = sdk.U32Val.fromVal(elem).toU32();
            total += elem_u32;
        }

        return sdk.U32Val.fromU32(total);
    }
};

comptime {
    _ = sdk.contract.exportContract(AllocContract);
}
