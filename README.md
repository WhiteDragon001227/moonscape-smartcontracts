# Moonscape &ndash; a free, p2e game on Moonbeam
[![Watch the Moonscape trailer](https://moonscapegame.com/assets/img/bg/gaming-bg1.webp)](https://www.youtube.com/watch?v=ncuh37dSrYg)

> **Official website:** https://moonscapegame.com/

**Moonscape** is a free *play to earn* game exclusively on [Moonbeam](https://moonbeam.network/) blockchain. It was developed by **BitPunch** studio, and published by [Seascape Network](https://seascape.network/).

**Moonscape** was the first fundraised project of [Lighthouse](https://seascape.house/).

This repository contains the smartcontracts of **Moonscape**.

---
## Smartcontracts

* `contracts/nfts` &ndash; The NFTs of Moonscape game.
* `contracts/mscp` &ndash; [MSCP](https://coinmarketcap.com/currencies/moonscape/) a native token of the game.
* `contracts/beta` &ndash; The smartcontract used as a gate for Close Beta version of the game.
* `contracts/game` &ndash; The blockchain related gameplay inside the game. *e.g import/export nft, purchase in game resource*.
* `contracts/defi` &ndash; The DeFi integration into the game. 

---
## Installation
Create `.env` file on the root folder by adding the following variables:

```
MOONBASE_PRIV_KEY=
MOONBASE_NODE_URL=https://rpc.api.moonbase.moonbeam.network
MOONBEAM_PRIV_KEY=
MOONBEAM_NODE_URL=https://rpc.api.moonbeam.network

ACCOUNT_1=
ACCOUNT_2=
```

Set your privatekeys for `*_PRIV_KEY` variables and in `ACCOUNT_*` variables.

> The **ACCOUNT_1** and **ACCOUNT_2** are used in local development. So it could be any private keys without any funds on any network.

---

Then, start the docker container:

```
docker-compose up -d
```


---

In order to deploy or test the smartcontracts, enter into the container:

```
docker exec -it moonscape-smartcontract bash
```

Then call `truffle compile` to compile solidity code. Or call `truffle migrate <file name in migrations> --network <network name>` to deploy on network.

---
Once you finished the working on the project, its better to close the containers.

First exit from container:

```
exit
```

Then shut down the container:

```
docker-compose down
```