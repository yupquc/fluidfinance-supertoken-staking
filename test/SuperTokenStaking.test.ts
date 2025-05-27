import { loadFixture, time } from "@nomicfoundation/hardhat-network-helpers";
import { expect } from "chai";
import { BigNumber } from "ethers";
import { ethers, upgrades } from "hardhat";
import { ONE_YEAR } from "./helpers";

describe("SuperTokenStaking", function () {
  async function deployFixture() {
    const Token = await ethers.getContractFactory("MockERC20");
    const token = await Token.deploy();

    const [owner, acc1, acc2] = await ethers.getSigners();

    return {
      owner,
      acc1,
      acc2,
      token,
    };
  }

  describe("stake", async () => {
    it("reverted with invalid params and condition", async () => {
      const { acc1 } = await loadFixture(deployFixture);
    });

    it("succeed when all conditions are met", async () => {
      const { acc1 } = await loadFixture(deployFixture);
    });
  });

  describe("unstake", async () => {
    it("reverted with invalid params and condition", async () => {
      const { acc1 } = await loadFixture(deployFixture);
    });

    it("succeed when all conditions are met", async () => {
      const { acc1 } = await loadFixture(deployFixture);
    });
  });
});
