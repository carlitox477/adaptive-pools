
# Adaptive Pools
![AdaptivePools Banner](./img/Banner_Shorter.png)
AdaptivePools: *An adaptive implementation of Uniswap V4 Liquidity Pools via hooks*

## Why AdaptivePools?
Liquidity Pools and AMM are a fundamental part of DeFi, but over time, their initial implementation starts to change to adapt to market needs. 

AdaptivePools helps liquidity providers to improve their rewards and traders to have enough liquidity to perform profitable and huge trades, leading to a win win situation by adapting the pool to the market momentum. 

## Sounds good, but how?
Uniswap V4 introduces hooks within their Liquidity Pools, therefore allowing us to interact with the contract based on constantly changing situations as liquidy supply, price market volatily and high or low trade demand. 

For it, we modify pool fee within a settable range to make 2 things:
- Under low trade demand, we can reduce the pool fee so best trade routing mechanisms like 1inch or Matcha will find our pool and the LP get more trades
- Under high trade demand, we can increase the pool fee as trades are gonna happen due to the momentum of the market, therefore, increasing liquidity providers rewards

Additionally, this incentivize huge liquidity, this liquidity provided creates consistent trades where price impact is minimum, therefore, making healthier the user trades.

## Okay but, what if in some point we still don't have enough liquidity
Adaptive Pools adapts themselve to low liquidity situations by using the concept of flash liquidity, for it, by using Uniswap V4 Hooks we take  Morpho Blue pools liquidity, making a seamless and optimal trade  

## Maths behind
This strategy works under the following math formula that analyzes last epochs to adapt to the market situation:
```latex
##### FORMULA
```

Here is our [whitepaper](link).

## Strategies
Last sections is the default strategy of AdaptivePools, but different strategies can be later provide after some iterations, as the core infraestructure

Additionally, this strategy can be unselected and use a fixed fees strategy without needing to redeploy the pool, meaning more flexibility, and more liquidity concentrated just within one pool 

## How to deploy your own AdaptivePool in less than 5 minutes 👀

It's as simple as filling a few fields asked by our deployment script and there you go!
- Choose a base fee amount, min range fee and max range fee
- Choose a pair of tokens
- Choose an adaptive fee strategy (optional)(wip)

## User interface
We provide a CLI interface to interact with the code in basic way:
- Deploy an AdaptivePool in just 2 steps
- Provide liquidity (this is for tests, you can do it interacting with uniswap v4 as long as they launch)
- Swap (this is for tests, you can do it interacting with uniswap v4 as long as they launch)
- Test your gains with adaptive strategy 

## Foundry

> Note: This repository is using custom `solc` binaries to support transient storage opcodes in inline assembly blocks
```
forge build --use bin/solc
forge test  --use bin/solc
```


### References
- [tstore-template](https://github.com/hrkrshnn/tstore-template/tree/master) by hrkrshnn

