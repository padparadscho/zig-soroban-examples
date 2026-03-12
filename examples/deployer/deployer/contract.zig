//! Factory Contract
//!
//! This contract demonstrates how to implement a factory contract that can deploy other contracts
//!
//! Build: `zig build factory`
//! Deploy: `stellar contract deploy --wasm zig-out/bin/factory.wasm --alias factory --source deployer`
//! Invoke:
//!         - init: `stellar contract invoke --id factory --source admin --network testnet -- init --admin admin`
//!         - `WASM_HASH=$(stellar contract upload --wasm zig-out/bin/simple_contract.wasm --source deployer --network testnet)`
//!         - `SALT=$(openssl rand -hex 32)`
//!         - get_contract_id: `stellar contract invoke --id factory --source admin --network testnet -- get_contract_id --salt $SALT`
//!         - deploy: `stellar contract invoke --id factory --source admin --network testnet -- deploy /
//!                    --wasm_hash $WASM_HASH --salt $SALT --constructor_args '[{"u32": 42}]'`

const sdk = @import("soroban-sdk");

///
const ADMIN = sdk.Symbol.fromString("Admin");

const FactoryContract = struct {
    pub const init_params = [_][]const u8{"admin"};

    /// Initialize the factory contract
    ///
    /// # Arguments
    ///
    /// * `admin` - The Address that is authorized to deploy new contracts
    pub fn init(admin: sdk.Address) void {
        admin.requireAuth();

        sdk.ledger.putContractData(ADMIN.toVal(), admin.toVal(), .instance);
    }

    pub const deploy_params = [_][]const u8{ "wasm_hash", "salt", "constructor_args" };

    /// Deploy a new contract with constructor arguments
    ///
    /// # Arguments
    ///
    /// * `wasm_hash` - The WASM hash of the contract to deploy
    /// * `salt` - A unique salt value
    /// * `constructor_args` - Constructor args encoded as `Vec<any>` SCVal JSON values
    pub fn deploy(wasm_hash: sdk.Bytes, salt: sdk.Bytes, constructor_args: sdk.Vec) sdk.Address {
        // Require that the admin is authenticated
        const admin_val = sdk.ledger.getContractData(ADMIN.toVal(), .instance);
        const admin = sdk.Address.fromVal(admin_val);
        admin.requireAuth();

        const deployer_addr = sdk.ledger.getCurrentContractAddress();

        // Deploy the contract with constructor arguments
        const deployed_addr = sdk.ledger.createContractWithConstructor(
            deployer_addr,
            wasm_hash,
            salt,
            constructor_args,
        );

        return deployed_addr;
    }

    pub const get_contract_id_params = [_][]const u8{"salt"};

    /// Get the predicted address for a contract with given salt
    ///
    /// # Arguments
    ///
    /// * `salt` - The exact salt to use for deterministic address derivation
    pub fn get_contract_id(salt: sdk.Bytes) sdk.Address {
        const deployer_addr = sdk.ledger.getCurrentContractAddress();
        return sdk.ledger.getContractId(deployer_addr, salt);
    }
};

comptime {
    _ = sdk.contract.exportContract(FactoryContract);
}
