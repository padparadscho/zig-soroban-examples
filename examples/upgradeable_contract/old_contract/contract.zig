//! Upgradeable Contract (v1)
//!
//! This contract demonstrates a simple upgradeable contract pattern
//!
//! Build: `zig build old_contract`
//! Deploy: `stellar contract deploy --wasm zig-out/bin/old_contract.wasm --alias old_contract --source deployer`
//! Invoke:
//!   - `stellar contract invoke --id old_contract --source deployer -- init --admin admin`
//!   - `stellar contract invoke --id old_contract --source deployer -- version`
//!   - `WASM_HASH=$(stellar contract upload --wasm zig-out/bin/new_contract.wasm --source deployer --network testnet)`
//!   - `stellar contract invoke --id old_contract --source admin -- upgrade --new_wasm_hash $WASM_HASH`

const sdk = @import("soroban-sdk");

/// Storage key for the admin address
const ADMIN = sdk.Symbol.fromString("Admin");

const OldContract = struct {
    pub const init_params = [_][]const u8{"admin"};

    /// Initializes the contract with an admin address
    ///
    /// # Arguments
    ///
    /// * `admin` - The Address that is authorized to upgrade the contract
    pub fn init(admin: sdk.Address) void {
        admin.requireAuth();

        sdk.ledger.putContractData(ADMIN.toVal(), admin.toVal(), .instance);
    }

    /// Returns the current version of the contract
    ///
    /// # Arguments
    ///
    /// * None
    pub fn version() sdk.U32Val {
        return sdk.U32Val.fromU32(1);
    }

    pub const upgrade_params = [_][]const u8{"new_wasm_hash"};

    /// Upgrades the contract to a new WASM
    ///
    /// # Arguments
    ///
    /// * `new_wasm_hash` - The WASM hash of the new contract to upgrade to
    pub fn upgrade(new_wasm_hash: sdk.Bytes) void {
        const admin_val = sdk.ledger.getContractData(ADMIN.toVal(), .instance);
        const admin = sdk.Address.fromVal(admin_val);
        admin.requireAuth();

        sdk.ledger.updateCurrentContractWasm(new_wasm_hash);
    }
};

comptime {
    _ = sdk.contract.exportContract(OldContract);
}
