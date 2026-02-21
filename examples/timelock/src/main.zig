//! Timelock Contract
//!
//! This contract demonstrates how to write a timelock and implements a greatly simplified claimable balance
//!
//! Build: `zig build timelock`
//! Deploy: `stellar contract deploy --wasm zig-out/bin/timelock.wasm --source <account-private-key>`
//! Invoke:
//!   - `stellar contract invoke --id <contract-id> --source <account-private-key> --network testnet -- /
//!     deposit --from <account-public-key> --token <stellar-asset-contract-id> --amount <i128> /
//!     --claimants '[{"address": "<address-1>"},{"address": "<address-2>"}]' --time_bound_kind <u32> --time_bound_timestamp <u64>`
//!   - `stellar contract invoke --id <contract-id> --source <account-private-key> --network testnet -- claim --claimant <account-public-key>`

const sdk = @import("soroban-sdk");

// Storage keys
const INIT_KEY = sdk.Symbol.fromString("INIT");
const BALANCE_KEY = sdk.Symbol.fromString("BALANCE");

/// TimeBoundKind values
const TIME_BOUND_KIND_BEFORE: u32 = 0;
const TIME_BOUND_KIND_AFTER: u32 = 1;

/// Maximum number of claimants allowed
const MAX_CLAIMANTS: usize = 10;

/// Custom error codes
const Error = enum(u32) {
    AlreadyInitialized = 1,
    TimeBoundNotMet = 2,
    NotClaimant = 3,
    TooManyClaimants = 4,
};

const TimelockContract = struct {
    pub const deposit_params = [_][]const u8{ "from", "token", "amount", "claimants", "time_bound_kind", "time_bound_timestamp" };

    /// Deposits tokens into the contract that can be claimed by the specified claimants
    /// 'after' or 'before' a certain timestamp
    ///
    /// NOTE: It doesn't support multiple deposits or splitting the deposit among claimants
    ///
    /// # Arguments
    ///
    /// * `from` - The address whose tokens are being deposited
    /// * `token` - The token contract address, see https://developers.stellar.org/docs/tokens/stellar-asset-contract
    /// * `amount` - The amount of tokens to deposit
    /// * `claimants` - The list of addresses that can claim the tokens
    /// * `time_bound_kind` - 0 = Before (claim before timestamp), 1 = After (claim after timestamp)
    /// * `time_bound_timestamp` - The timestamp for the time bound condition
    pub fn deposit(
        from: sdk.Address,
        token: sdk.Address,
        amount: sdk.I128Val,
        claimants: sdk.Vec,
        time_bound_kind: sdk.U32Val,
        time_bound_timestamp: sdk.U64Val,
    ) sdk.Void {
        // Check claimants limit
        if (claimants.len() > MAX_CLAIMANTS) {
            const error_val = sdk.val.Error.fromParts(0, @intFromEnum(Error.TooManyClaimants));
            sdk.ledger.failWithError(error_val);
        }

        // Check if already initialized (prevent double deposit)
        if (sdk.ledger.hasContractData(sdk.asVal(INIT_KEY), sdk.StorageType.instance)) {
            const error_val = sdk.val.Error.fromParts(0, @intFromEnum(Error.AlreadyInitialized));
            sdk.ledger.failWithError(error_val);
        }

        // Require auth from the sender
        from.requireAuth();

        // Transfer tokens from the sender to the contract
        const token_client = sdk.token.TokenClient.init(token);
        token_client.transfer(from, sdk.ledger.getCurrentContractAddress(), amount);

        // Store the claimable balance (instance storage, matching Rust)
        var balance = sdk.Map.new();
        balance.set(sdk.Symbol.fromString("token"), token.toVal());
        balance.set(sdk.Symbol.fromString("amount"), amount.toVal());
        balance.set(sdk.Symbol.fromString("claimants"), claimants.toVal());
        balance.set(sdk.Symbol.fromString("time_bound_kind"), time_bound_kind.toVal());
        balance.set(sdk.Symbol.fromString("time_bound_timestamp"), time_bound_timestamp.toVal());

        sdk.ledger.putContractData(sdk.asVal(BALANCE_KEY), balance.toVal(), sdk.StorageType.instance);

        // Mark as initialized (after successful deposit)
        sdk.ledger.putContractData(sdk.asVal(INIT_KEY), sdk.asVal(sdk.Void.VOID), sdk.StorageType.instance);

        return sdk.Void.VOID;
    }

    pub const claim_params = [_][]const u8{"claimant"};

    /// Claims the deposited tokens if the caller is a claimant and the time bound is met
    ///
    /// # Arguments
    ///
    /// * `claimant` - The address claiming the tokens
    pub fn claim(claimant: sdk.Address) sdk.Void {
        // Require auth from the claimant
        claimant.requireAuth();

        // Get the stored balance
        const balance_val = sdk.ledger.getContractData(sdk.asVal(BALANCE_KEY), sdk.StorageType.instance);
        const balance = sdk.Map.fromVal(balance_val);

        // Get claimants and check if the claimant is in the list
        const claimants = sdk.Vec.fromVal(balance.get(sdk.Symbol.fromString("claimants")));
        if (claimants.contains(claimant) == false) {
            const error_val = sdk.val.Error.fromParts(0, @intFromEnum(Error.NotClaimant));
            sdk.ledger.failWithError(error_val);
        }

        // Get time bound and check if conditions are met
        const kind = sdk.U32Val.fromVal(balance.get(sdk.Symbol.fromString("time_bound_kind"))).toU32();
        const timestamp: u64 = @as(u64, sdk.U64Val.fromVal(balance.get(sdk.Symbol.fromString("time_bound_timestamp"))).toSmall());
        const current_timestamp: u64 = @as(u64, sdk.ledger.getLedgerTimestamp().toSmall());

        const time_bound_met = switch (kind) {
            TIME_BOUND_KIND_BEFORE => current_timestamp <= timestamp,
            TIME_BOUND_KIND_AFTER => current_timestamp >= timestamp,
            else => false,
        };

        if (time_bound_met == false) {
            const error_val = sdk.val.Error.fromParts(0, @intFromEnum(Error.TimeBoundNotMet));
            sdk.ledger.failWithError(error_val);
        }

        // Get token and amount
        const token = sdk.Address.fromVal(balance.get(sdk.Symbol.fromString("token")));
        const amount = sdk.I128Val.fromVal(balance.get(sdk.Symbol.fromString("amount")));

        // Delete the balance
        sdk.ledger.delContractData(sdk.asVal(BALANCE_KEY), sdk.StorageType.instance);

        // Transfer tokens to the claimant
        const token_client = sdk.token.TokenClient.init(token);
        token_client.transfer(
            sdk.ledger.getCurrentContractAddress(),
            claimant,
            amount,
        );

        return sdk.Void.VOID;
    }
};

comptime {
    _ = sdk.contract.exportContract(TimelockContract);
}
