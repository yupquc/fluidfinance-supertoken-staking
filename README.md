# Portal Smart Contracts

This project is backed by [Hardhat](https://hardhat.org/hardhat-runner/docs/getting-started).



## Testing

Running tests

```shell
npm run test
```

Run a specific test

```shell
npx hardhat test --grep "TestName"
```

## Deployment

```shell
npx hardhat run scripts/deploy.ts --network bscTestnet
npx hardhat clean
npx hardhat verify --network bscTestnet $CONTRACT_ADDRESS
```