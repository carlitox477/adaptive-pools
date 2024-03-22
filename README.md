
# Adaptive Pools
![AdaptivePools Banner](./img/Banner_Shorter.png)
AdaptivePools: *An adaptive implementation of Uniswap V4 Liquidity Pools via hooks*

## Table of Contents

- [Why AdaptivePools?](#why-adaptivepools)
- [Sounds good, but how?](#sounds-good-but-how)
- [Okay but, what if in some point we still don't have enough liquidity](#okay-but-what-if-in-some-point-we-still-dont-have-enough-liquidity)
- [Maths behind](#maths-behind)
  - [How we do it](#how-we-do-it)
  - [How do we track volume](#how-do-we-track-volume)
  - [Authors](#authors)
- [Strategies](#strategies)
- [How to deploy your own AdaptivePool in less than 5 minutes 👀](#how-to-deploy-your-own-adaptivepool-in-less-than-5-minutes-)
- [User interface](#user-interface)
- [Foundry](#foundry)
  - [References](#references)

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

* $EPOCHS\_ TO\_ TRACK$: We must track liquidity utilized in last $EPOCHS\_ TO\_ TRACK$ epochs to be able to calculate the average utilzed liquidity in these periods
* $EPOCHS\_ DURATION$: Duration of one epoch in seconds
* $volumeOfLiquidityUtilized$: Liquidity that has been utilized during current epoch (can be interpreted as volume trade during current epoch)
* $sumLastEpochLiquidityVolume = \sum_{i = 1}^{|trackedEpochsVolumes|}(trackedEpochsVolumes[i])$
* $AvgLiquidityUtilized = \frac{SumLastEpochLiquidityVolume}{NumberOfEpochsToTrack}$
* $AVG\_ VOLUME\_ THRESHOLD$: Percentage of AVG volume transactioned in last $EPOCHS\_ TO\_ TRACK$ that we are going to take into account in order to increase/decrease swap fees
* $MIN\_FEE$: Min fee percentage that liquidity providers and Uniswap are going to receive in each swap. If volume transactioned during last epoch is
* $MAX\_ FEE$: Max fee percentage that liquidity providers and Uniswap are going to receive in each swap.
* $NORMAL\_ FEE$: Normal fee percentage
* $DELTA\_ FEE$: Percentage that swap fees can increase/decrease in each epoch

### How we do it
We track a moving average of a value that represents traded volume inside an epoch, and if we desviate enough from this value we are going to increase or decrease fee percentage by $DELTA\_ FEE$ unless current swap fees are the one desired.

The idea is that:
* If $AvgLiquidityUtilized \times (100\% - AVG\_ VOLUME\_ THRESHOLD) \leq volumeOfLiquidityUtilized \leq  AvgLiquidityUtilized \times (100\% + AVG\_ VOLUME\_ THRESHOLD)$ swap fees should tend to $NORMAL\_ FEE$
* $volumeOfLiquidityUtilized < AvgLiquidityUtilized \times (100\% - AVG\_ VOLUME\_ THRESHOLD)$ swap fees should tend to $MIN\_ FEE$
* $volumeOfLiquidityUtilized > AvgLiquidityUtilized \times (100\% - AVG\_ VOLUME\_ THRESHOLD)$ swap fees should tend to $MAX\_ FEE$


![Swap fees trend trend](https://i.ibb.co/6m13zGG/Uniswap-dynamic-fees-P-gina-3.png)

### How do we track volume
We can consider the liquidity utilized for swapping in an epoch as a valid measure of transacted volume without needing to convert values in another unit of measure like USD in each swap. To calculate the liquidity utilize in a swap we can use the amount of tokens swapped in and the global fee growth per liquidity unit of token swapped in to calculate liquidity utilized during a swap in next way

$UtilizedLiquidity_{swap} = \frac{swapIn_{X}}{globalFeeGrowthTokenX_{after \; swap} - globalFeeGrowthTokenX_{before \; swap}}$

Each time we do a swap we can calculate this value in `afterSwapHook` if in `beforeSwapHook` we save $globalFeeGrowthTokenX_{before \; swap}$

Each time we do a swap we must add this value to $volumeOfLiquidityUtilized$

### Authors
* [carlitox477](https://twitter.com/carlitox477)
* [Deivitto](https://twitter.com/Deivitto)
* [Pablo Misirov](https://twitter.com/p_misirov)

### Slides
- https://docs.google.com/presentation/d/1DokPI8LZ3-d-dhV_sWuj_R5zaoTYGPtNbd1bAVkS1qg/edit#slide=id.p

## Strategies
Last sections is the default strategy of AdaptivePools, but different strategies can be later provide after some iterations, as the core infraestructure

Additionally, this strategy can be unselected and use a fixed fees strategy without needing to redeploy the pool, meaning more flexibility, and more liquidity concentrated just within one pool 

## How to deploy your own AdaptivePool in less than 5 minutes 👀

It's as simple as filling a few fields asked by our deployment script and there you go!
- Choose a base fee amount, min range fee and max range fee
- Choose a pair of tokens
- Choose an adaptive fee strategy (optional)

## User interface
We provide a CLI interface to interact with the code in basic way:
- Deploy an AdaptivePool in just 2 steps
- Provide liquidity (this is for tests, you can do it interacting with uniswap v4 as long as they launch)
- Swap (this is for tests, you can do it interacting with uniswap v4 as long as they launch)

## Foundry

> Note: This repository is using custom `solc` binaries to support transient storage opcodes in inline assembly blocks
```
forge build --use bin/solc
forge test  --use bin/solc
```

#### References
- [Math spec](https://hackmd.io/iHO3hvF9RAqIVAE4bNgxEA?view)
- [tstore-template](https://github.com/hrkrshnn/tstore-template/tree/master) by hrkrshnn

