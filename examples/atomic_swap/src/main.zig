//! Atomic Swap Contract
//!
//! A contract that enables atomic token swaps between two parties without requiring them to trust each other
//!
//! Build: `zig build atomic_swap`
//! Deploy: `stellar contract deploy --wasm zig-out/bin/atomic_swap.wasm --alias atomic_swap --source deployer`
//! Invoke: `stellar contract invoke --id atomic_swap --source user --network testnet /
//!          -- swap --a sender --b receiver --token_a <stellar-asset-contract-id> --token_b <stellar-asset-contract-id> /
//!          --amount_a <i128> --min_b_for_a <i128> --amount_b <i128> --min_a_for_b <i128>`

const sdk = @import("soroban-sdk");

const AtomicSwapContract = struct {
    pub const swap_params = [_][]const u8{ "a", "b", "token_a", "token_b", "amount_a", "min_b_for_a", "amount_b", "min_a_for_b" };

    /// Performs an atomic swap between two parties
    ///
    /// Party A offers `amount_a` of `token_a` and wants at least `min_b_for_a` of `token_b`
    /// Party B offers `amount_b` of `token_b` and wants at least `min_a_for_b` of `token_a`
    ///
    /// The swap only succeeds if:
    /// - amount_b >= min_b_for_a
    /// - amount_a >= min_a_for_b
    ///
    /// Both parties must authorize the swap with their specific arguments
    ///
    /// # Arguments
    ///
    /// * `a` - Address of party A (offering token_a)
    /// * `b` - Address of party B (offering token_b)
    /// * `token_a` - Address of the token contract for token A
    /// * `token_b` - Address of the token contract for token B
    /// * `amount_a` - Amount of token A that party A offers
    /// * `min_b_for_a` - Minimum amount of token B that party A requires
    /// * `amount_b` - Amount of token B that party B offers
    /// * `min_a_for_b` - Minimum amount of token A that party B requires
    pub fn swap(
        a: sdk.Address,
        b: sdk.Address,
        token_a: sdk.Address,
        token_b: sdk.Address,
        amount_a: sdk.I128Val,
        min_b_for_a: sdk.I128Val,
        amount_b: sdk.I128Val,
        min_a_for_b: sdk.I128Val,
    ) void {
        const amount_a_i128 = sdk.int.i128FromVal(amount_a);
        const amount_b_i128 = sdk.int.i128FromVal(amount_b);
        const min_b_for_a_i128 = sdk.int.i128FromVal(min_b_for_a);
        const min_a_for_b_i128 = sdk.int.i128FromVal(min_a_for_b);

        if (amount_b_i128 < min_b_for_a_i128) {
            sdk.failContract(1);
        }
        if (amount_a_i128 < min_a_for_b_i128) {
            sdk.failContract(2);
        }

        const args_a = sdk.Vec.from(.{ token_a, token_b, amount_a, min_b_for_a });
        a.requireAuthForArgs(args_a);

        const args_b = sdk.Vec.from(.{ token_b, token_a, min_a_for_b, amount_b });
        b.requireAuthForArgs(args_b);

        const contract_addr = sdk.env.context.get_current_contract_address();

        // Move token_a from party A to party B
        const token_a_client = sdk.token.TokenClient.init(token_a);
        moveToken(&token_a_client, a, b, amount_a_i128, min_a_for_b_i128, contract_addr);

        // Move token_b from party B to party A
        const token_b_client = sdk.token.TokenClient.init(token_b);
        moveToken(&token_b_client, b, a, amount_b_i128, min_b_for_a_i128, contract_addr);
    }
};

comptime {
    _ = sdk.contract.exportContract(AtomicSwapContract);
}

// -- Helper functions --

/// Moves tokens from one party to another via the contract as intermediary
///
/// 1. Transfers `max_spend_amount` from `from` to the contract
/// 2. Transfers `transfer_amount` from the contract to `to`
/// 3. Refunds the remaining balance (max_spend_amount - transfer_amount) to `from`
///
/// # Arguments
///
/// * `token` - The token contract client
/// * `from` - The address sending tokens
/// * `to` - The address receiving tokens
/// * `max_spend_amount` - Maximum amount to spend from `from`
/// * `transfer_amount` - Amount to transfer to `to`
/// * `contract_addr` - The atomic swap contract's address
fn moveToken(
    token: *const sdk.token.TokenClient,
    from: sdk.Address,
    to: sdk.Address,
    max_spend_amount: i128,
    transfer_amount: i128,
    contract_addr: sdk.Address,
) void {
    const amount_i128val = sdk.int.i128ToVal(max_spend_amount);
    token.transfer(from, contract_addr, amount_i128val);

    const transfer_i128val = sdk.int.i128ToVal(transfer_amount);
    token.transfer(contract_addr, to, transfer_i128val);

    const refund = max_spend_amount - transfer_amount;
    if (refund > 0) {
        const refund_i128val = sdk.int.i128ToVal(refund);
        token.transfer(contract_addr, from, refund_i128val);
    }
}
