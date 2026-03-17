//! Token Contract
//!
//! This contract demonstrates a basic fungible token implementing the SEP-41 Token Interface
//!
//! Build: `zig build token`
//! Deploy: `stellar contract deploy --wasm zig-out/bin/token.wasm --alias token --source deployer --network testnet /
//!          -- --admin admin --decimal 7 --token_name '"Test Token"' --token_symbol '"TEST"'`
//! Invoke:
//!         - mint: `stellar contract invoke --id token --source admin --network testnet -- mint --to me --amount 10000000`
//!         - balance: `stellar contract invoke --id token --source me --network testnet -- balance --id me`
//!         - transfer: `stellar contract invoke --id token --source me --network testnet -- transfer --from me --to recipient --amount 500000`
//!         - burn: `stellar contract invoke --id token --source me --network testnet -- burn --from me --amount 200000`

const sdk = @import("soroban-sdk");

const admin_mod = @import("admin.zig");
const allowance_mod = @import("allowance.zig");
const balance_mod = @import("balance.zig");
const metadata_mod = @import("metadata.zig");
const storage = @import("storage_types.zig");

const TokenContract = struct {
    // -- Constructor --

    pub const __constructor_params = [_][]const u8{ "admin", "decimal", "token_name", "token_symbol" };

    /// Initializes the token contract
    ///
    /// # Arguments:
    ///
    /// * `admin` - The address that will have admin privileges
    /// * `decimal` - The decimals of the token, must be <= 18
    /// * `token_name` - The name of the token
    /// * `token_symbol` - The symbol of the token
    pub fn __constructor(
        admin: sdk.Address,
        decimal: sdk.U32Val,
        token_name: sdk.String,
        token_symbol: sdk.String,
    ) sdk.Void {
        const d = decimal.toU32();

        if (d > 18) {
            sdk.failContract(1);
        }
        admin_mod.write(admin);
        metadata_mod.writeDecimals(d);
        metadata_mod.writeName(token_name);
        metadata_mod.writeSymbol(token_symbol);
        return sdk.Void.VOID;
    }

    // -- Admin Functions --

    pub const mint_params = [_][]const u8{ "to", "amount" };

    /// Mints new tokens to an address
    ///
    /// # Arguments:
    ///
    /// * `to` - The address to receive the minted tokens
    /// * `amount` - The amount of tokens to mint
    pub fn mint(to: sdk.Address, amount: sdk.I128Val) sdk.Void {
        const amt = sdk.int.i128FromVal(amount);
        if (amt <= 0) {
            sdk.failContract(2);
        }
        const admin_addr = admin_mod.read();
        admin_addr.requireAuth();
        balance_mod.receive(to, amt);
        sdk.token.emitMint(to, amount);
        return sdk.Void.VOID;
    }

    pub const set_admin_params = [_][]const u8{"new_admin"};

    /// Transfers admin role to new address
    ///
    /// # Arguments:
    ///
    /// * `new_admin` - The address to transfer admin role to
    pub fn set_admin(new_admin: sdk.Address) sdk.Void {
        const current_admin = admin_mod.read();
        current_admin.requireAuth();
        admin_mod.write(new_admin);
        sdk.token.emitSetAdmin(current_admin, new_admin);
        return sdk.Void.VOID;
    }

    // -- SEP-41 Token Interface --

    pub const allowance_params = [_][]const u8{ "from", "spender" };

    /// Returns the allowance amount for spender
    ///
    /// # Arguments:
    ///
    /// * `from` - The address which sets the allowance
    /// * `spender` - The address which can spend the allowance
    pub fn allowance(from: sdk.Address, spender: sdk.Address) sdk.I128Val {
        sdk.ledger.extendCurrentContractInstanceAndCodeTtl(
            storage.INSTANCE_LIFETIME_THRESHOLD,
            storage.INSTANCE_BUMP_AMOUNT,
        );
        return sdk.int.i128ToVal(allowance_mod.read(from, spender).amount);
    }

    pub const approve_params = [_][]const u8{ "from", "spender", "amount", "expiration_ledger" };

    /// Sets allowance for spender
    ///
    /// # Arguments:
    ///
    /// * `from` - The address which sets the allowance
    /// * `spender` - The address which can spend the allowance
    /// * `amount` - The amount of tokens to allow
    /// * `expiration_ledger` - The ledger at which the allowance expires
    pub fn approve(
        from: sdk.Address,
        spender: sdk.Address,
        amount: sdk.I128Val,
        expiration_ledger: sdk.U32Val,
    ) sdk.Void {
        from.requireAuth();
        const amt = sdk.int.i128FromVal(amount);
        if (amt < 0) {
            sdk.failContract(2);
        }
        sdk.ledger.extendCurrentContractInstanceAndCodeTtl(
            storage.INSTANCE_LIFETIME_THRESHOLD,
            storage.INSTANCE_BUMP_AMOUNT,
        );
        allowance_mod.write(from, spender, amt, expiration_ledger.toU32());
        sdk.token.emitApprove(from, spender, amount, expiration_ledger);
        return sdk.Void.VOID;
    }

    pub const balance_params = [_][]const u8{"id"};

    /// Returns the balance of an address
    ///
    /// # Arguments:
    ///
    /// * `id` - The address to query balance for
    pub fn balance(id: sdk.Address) sdk.I128Val {
        sdk.ledger.extendCurrentContractInstanceAndCodeTtl(
            storage.INSTANCE_LIFETIME_THRESHOLD,
            storage.INSTANCE_BUMP_AMOUNT,
        );
        return sdk.int.i128ToVal(balance_mod.read(id));
    }

    pub const transfer_params = [_][]const u8{ "from", "to", "amount" };

    /// Transfers tokens from one address to another
    ///
    /// # Arguments:
    ///
    /// * `from` - The address which sends the tokens
    /// * `to` - The address which receives the tokens
    /// * `amount` - The amount of tokens to transfer
    pub fn transfer(from: sdk.Address, to: sdk.Address, amount: sdk.I128Val) sdk.Void {
        from.requireAuth();
        const amt = sdk.int.i128FromVal(amount);
        if (amt <= 0) {
            sdk.failContract(2);
        }
        sdk.ledger.extendCurrentContractInstanceAndCodeTtl(
            storage.INSTANCE_LIFETIME_THRESHOLD,
            storage.INSTANCE_BUMP_AMOUNT,
        );
        balance_mod.spend(from, amt);
        balance_mod.receive(to, amt);
        sdk.token.emitTransfer(from, to, amount);
        return sdk.Void.VOID;
    }

    pub const transfer_from_params = [_][]const u8{ "spender", "from", "to", "amount" };

    /// Transfers tokens using allowance
    ///
    /// # Arguments:
    ///
    /// * `spender` - The address which spends the allowance
    /// * `from` - The address which sets the allowance and sends the tokens
    /// * `to` - The address which receives the tokens
    /// * `amount` - The amount of tokens to transfer
    pub fn transfer_from(
        spender: sdk.Address,
        from: sdk.Address,
        to: sdk.Address,
        amount: sdk.I128Val,
    ) sdk.Void {
        spender.requireAuth();
        const amt = sdk.int.i128FromVal(amount);
        if (amt <= 0) {
            sdk.failContract(2);
        }
        sdk.ledger.extendCurrentContractInstanceAndCodeTtl(
            storage.INSTANCE_LIFETIME_THRESHOLD,
            storage.INSTANCE_BUMP_AMOUNT,
        );
        allowance_mod.spend(from, spender, amt);
        balance_mod.spend(from, amt);
        balance_mod.receive(to, amt);
        sdk.token.emitTransfer(from, to, amount);
        return sdk.Void.VOID;
    }

    pub const burn_params = [_][]const u8{ "from", "amount" };

    /// Burns tokens from an address
    ///
    /// # Arguments:
    ///
    /// * `from` - The address which burns the tokens
    /// * `amount` - The amount of tokens to burn
    pub fn burn(from: sdk.Address, amount: sdk.I128Val) sdk.Void {
        from.requireAuth();
        const amt = sdk.int.i128FromVal(amount);
        if (amt <= 0) {
            sdk.failContract(2);
        }
        sdk.ledger.extendCurrentContractInstanceAndCodeTtl(
            storage.INSTANCE_LIFETIME_THRESHOLD,
            storage.INSTANCE_BUMP_AMOUNT,
        );
        balance_mod.spend(from, amt);
        sdk.token.emitBurn(from, amount);
        return sdk.Void.VOID;
    }

    pub const burn_from_params = [_][]const u8{ "spender", "from", "amount" };

    /// Burns tokens using allowance
    ///
    /// # Arguments:
    ///
    /// * `spender` - The address which spends the allowance
    /// * `from` - The address which sets the allowance and burns the tokens
    /// * `amount` - The amount of tokens to burn
    pub fn burn_from(
        spender: sdk.Address,
        from: sdk.Address,
        amount: sdk.I128Val,
    ) sdk.Void {
        spender.requireAuth();
        const amt = sdk.int.i128FromVal(amount);
        if (amt <= 0) {
            sdk.failContract(2);
        }
        sdk.ledger.extendCurrentContractInstanceAndCodeTtl(
            storage.INSTANCE_LIFETIME_THRESHOLD,
            storage.INSTANCE_BUMP_AMOUNT,
        );
        allowance_mod.spend(from, spender, amt);
        balance_mod.spend(from, amt);
        sdk.token.emitBurn(from, amount);
        return sdk.Void.VOID;
    }

    // -- Metadata --

    /// Returns the number of decimal places
    pub fn decimals() sdk.U32Val {
        return sdk.U32Val.fromU32(metadata_mod.readDecimals());
    }

    /// Returns the token name
    pub fn name() sdk.String {
        return metadata_mod.readName();
    }

    /// Returns the token symbol
    pub fn symbol() sdk.String {
        return metadata_mod.readSymbol();
    }
};

comptime {
    _ = sdk.contract.exportContract(TokenContract);
}
