> [!WARNING]
> Due to the experimental status of the Soroban SDK for Zig, these examples are intended for educational purposes and may not be production-ready.
> Use at your own risk.

# Zig Soroban Examples

A collection of **Soroban smart contract** examples written in **Zig**. The examples illustrate how to use the features, in their simplest form.

## Prerequisites

- [Zig](https://ziglang.org/download/) 0.15.x
- [Stellar CLI](https://developers.stellar.org/docs/build/smart-contracts/getting-started/setup) 25.x

## Zig Soroban SDK

This project uses the [zig-soroban-sdk](https://github.com/leighmcculloch/zig-soroban-sdk) by **Leigh McCulloch**.

## Examples

| Example                               | Description                                            |
| ------------------------------------- | ------------------------------------------------------ |
| [hello](examples/hello)               | Demonstrates the basic structure of a Soroban contract |
| [increment](examples/increment)       | Demonstrates a simple counter that can be incremented  |
| [logging](examples/logging)           | Demonstrates terminal logging to emit debug logs       |
| [errors](examples/errors)             | Demonstrates how to define and handle custom errors    |
| [events](examples/events)             | Demonstrates how to emit structured events             |
| [custom_types](examples/custom_types) | Demonstrates how to define and use custom data types   |
| [auth](examples/auth)                 | Demonstrates authentication patterns                   |

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
stellar contract deploy --wasm zig-out/bin/hello.wasm --source <account-private-key> --network testnet
```

## Invoke

Invoke the contract:

```bash
# Example: Invoke the 'hello' contract
stellar contract invoke --id <contract-id> --source <account-private-key> --network testnet -- hello --to world
```

## Project Structure

```
zig-soroban-examples/
├── build.zig               # Build configuration
├── build.zig.zon           # Dependencies
├── README.md
└── examples/
    ├── hello/              # Hello World example
    │   └── src/main.zig
    └── ...                 # Additional examples
```

## License

This project is licensed under the [MIT License](/LICENSE).
