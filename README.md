> [!WARNING]
> Due to the experimental status of the Soroban SDK for Zig, these examples are intended for educational purposes and should not be used in production.
> Use at your own risk.

# Zig Soroban Examples

A collection of **Soroban smart contract** examples written in **Zig**. The examples illustrate how to use the features, in their simplest form.

## Prerequisites

- [Zig](https://ziglang.org/download/) 0.15.x
- [Stellar CLI](https://developers.stellar.org/docs/build/smart-contracts/getting-started/setup) 25.x

### Identities Setup

To deploy and interact with the contracts, set up Stellar accounts as needed using the Stellar CLI:

```bash
# Create Stellar accounts for deployer, user, sender, admin, etc.
stellar keys generate deployer --network testnet --fund
```

## Zig Soroban SDK

This project uses the [zig-soroban-sdk](https://github.com/leighmcculloch/zig-soroban-sdk) by **Leigh McCulloch**.

## Examples

| Example                                   | Description                                                      |
| ----------------------------------------- | ---------------------------------------------------------------- |
| [hello](examples/hello)                   | Demonstrates the basic structure of a Soroban contract           |
| [increment](examples/increment)           | Demonstrates a simple counter that can be incremented            |
| [logging](examples/logging)               | Demonstrates how to use the standard Soroban terminal logging    |
| [errors](examples/errors)                 | Demonstrates how to define and handle custom errors              |
| [events](examples/events)                 | Demonstrates how to define and emit custom events                |
| [custom_types](examples/custom_types)     | Demonstrates how to define and use custom data structures        |
| [auth](examples/auth)                     | Demonstrates how to implement basic authentication logic         |
| [timelock](examples/timelock)             | Demonstrates how to implement time-based conditions              |
| [cross_contract](examples/cross_contract) | Demonstrates how to call another contract from within a contract |
| [atomic_swap](examples/atomic_swap)       | Demonstrates a simple atomic swap between two parties            |

## Build

Build the contract:

```bash
# Example: Build the 'hello' contract
zig build hello
```

Compiled WASM file is output to `zig-out/bin/hello.wasm`.

## Deploy

Deploy to Stellar Testnet:

```bash
# Example: Deploy the 'hello' contract
stellar contract deploy --wasm zig-out/bin/hello.wasm --alias hello --source deployer --network testnet
```

## Invoke

Invoke the contract:

```bash
# Example: Invoke the 'hello' contract
stellar contract invoke --id hello --source user --network testnet -- hello --to world
```

## Project Structure

```
zig-soroban-examples/
├── build.zig               # Build configuration
├── build.zig.zon           # Dependencies
├── README.md
└── examples/
    ├── hello/              # Hello World example
    │   └── contract.zig
    └── ...                 # Additional examples
```

## License

This project is licensed under the [MIT License](/LICENSE).
