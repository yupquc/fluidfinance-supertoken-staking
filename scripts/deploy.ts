import hre from "hardhat";
import { ethers, upgrades, network } from "hardhat";

async function main() {
  const network = hre.network.name;

  const [owner] = await ethers.getSigners();

  const superToken = ""; // TODO
  const rewardToken = ""; // TODO

  console.log(
    `Deploy FluidFinance Staking Contract on: ${network} chain using with ${owner.address}`
  );

  const SuperTokenStaking = await ethers.getContractFactory(
    `contracts/SuperTokenStaking.sol:SuperTokenStaking`
  );
  const superTokenStaking = await upgrades.deployProxy(SuperTokenStaking, [
    [superToken, rewardToken],
  ]);

  console.log("SuperTokenStaking deployed to:", superTokenStaking.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
