//! Upgradeable Contract (v2)
//!
//! This is the upgraded version of the upgradeable contract
//!
//! Build: `zig build new_contract`
//! Invoke (after upgrade): `stellar contract invoke --id old_contract --source admin -- handle_upgrade`

const sdk = @import("soroban-sdk");

/// Storage key for the admin in v1
const ADMIN = sdk.Symbol.fromString("Admin");
/// Storage key for the new admin in v2
const NEW_ADMIN = sdk.Symbol.fromString("NewAdmin");

const NewContract = struct {
    pub const __constructor_params = [_][]const u8{ "admin", "new_admin" };

    /// The constructor is not called when the contract is upgraded, the new 'handle_upgrade'
    /// function brings the upgraded contract to a proper state
    ///
    /// # Arguments
    ///
    /// * `admin` - The original admin address
    /// * `new_admin` - The new admin address
    pub fn __constructor(admin: sdk.Address, new_admin: sdk.Address) void {
        sdk.ledger.putContractData(ADMIN.toVal(), admin.toVal(), .instance);
        sdk.ledger.putContractData(NEW_ADMIN.toVal(), new_admin.toVal(), .instance);
    }

    /// Copies ADMIN to NEW_ADMIN for the upgraded auth model
    ///
    /// # Arguments
    ///
    /// * None
    pub fn handle_upgrade() void {
        const admin_val = sdk.ledger.getContractData(ADMIN.toVal(), .instance);
        const admin = sdk.Address.fromVal(admin_val);
        admin.requireAuth();

        if (!sdk.ledger.hasContractData(NEW_ADMIN.toVal(), .instance)) {
            sdk.ledger.putContractData(NEW_ADMIN.toVal(), admin_val, .instance);
        }
    }

    /// NEW: Returns the value 42 to demonstrate new v2 functionality
    ///
    /// # Arguments
    ///
    /// * None
    pub fn new_v2_fn() sdk.U32Val {
        return sdk.U32Val.fromU32(42);
    }

    /// Returns the current version of the contract
    ///
    /// # Arguments
    ///
    /// * None
    pub fn version() sdk.U32Val {
        return sdk.U32Val.fromU32(2);
    }

    pub const upgrade_params = [_][]const u8{"new_wasm_hash"};

    /// Upgrades the contract to a new WASM, requires auth from the new admin
    ///
    /// # Arguments
    ///
    /// * `new_wasm_hash` - The WASM hash of the new contract to upgrade to
    pub fn upgrade(new_wasm_hash: sdk.Bytes) void {
        const new_admin_val = sdk.ledger.getContractData(NEW_ADMIN.toVal(), .instance);
        const new_admin = sdk.Address.fromVal(new_admin_val);
        new_admin.requireAuth();

        sdk.ledger.updateCurrentContractWasm(new_wasm_hash);
    }
};

comptime {
    _ = sdk.contract.exportContract(NewContract);
}
