AdaptivePools Hooks: *An adaptive implementation of Uniswap Liquidity Pools*


## Why AdaptivePools?
Liquidity Pools and AMM are a fundamental part of DeFi, but over time, their initial implementation starts to change to adapt to market needs.

AdaptivePools is here to solve this market neneds. While improving incentives to liquidity providers with higher rewards depending on market situation, we also back all type of traders by solving the liquidity issue, reducing the amount of times we see not enough liquidity within a price and providing enough liquidity for big trades.

## Sounds good, but how?
Uniswap V4 introduces hooks within their Liquidity Pools, therefore allowing us to interact with the contract based on constantly changing situations as price market volatily and high or low trade demand. 

For it, we modify pool fee within a settable range to make 2 things:
- Under low trade demand, we can reduce the pool fee so best routing mechanisms like 1inch or Matcha find our pool and we get more trades
- Under high trade demand, we can increase the pool fee as trades are gonna happen due to the momentum of the market, therefore, increasing liquidity providers rewards

This strategy works under the following math formula that analyzes last epochs to adapt to the market situation:
```latex
##### FORMULA
```

## Strategies
Last sections is the default strategy of AdaptivePools, but different strategies can be later provide after some iterations, as the core infraestructure

Additionally, this strategy can be unselected and use a fixed fees strategy without needing to redeploy the pool, meaning more flexibility, and more liquidity concentrated just within one pool 

## How to deploy your own AdaptivePool in less than 5 minutes 👀

It's as simple as following the 3 simple steps in our deployment script
- Choose a fee amount
- Choose a pair of tokens
- Choose an adaptive fee strategy

## Foundry

**Foundry is a blazing fast, portable and modular toolkit for Ethereum application development written in Rust.**

Foundry consists of:

-   **Forge**: Ethereum testing framework (like Truffle, Hardhat and DappTools).
-   **Cast**: Swiss army knife for interacting with EVM smart contracts, sending transactions and getting chain data.
-   **Anvil**: Local Ethereum node, akin to Ganache, Hardhat Network.
-   **Chisel**: Fast, utilitarian, and verbose solidity REPL.

## Documentation

https://book.getfoundry.sh/

## Usage

### Build

```shell
$ forge build
```

### Test

```shell
$ forge test
```

### Format

```shell
$ forge fmt
```

### Gas Snapshots

```shell
$ forge snapshot
```

### Anvil

```shell
$ anvil
```

### Deploy

```shell
$ forge script script/Counter.s.sol:CounterScript --rpc-url <your_rpc_url> --private-key <your_private_key>
```

### Cast

```shell
$ cast <subcommand>
```

### Help

```shell
$ forge --help
$ anvil --help
$ cast --help
```
