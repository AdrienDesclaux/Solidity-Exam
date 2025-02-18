const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("LiquidityPoolFactory", function () {
  let LiquidityPoolFactory;
  let factory;
  let owner;
  let addr1;
  let token0;
  let token1;
  let treasury;

  beforeEach(async function () {
    [owner, addr1, treasury] = await ethers.getSigners();

    // Deploy mock ERC20 tokens
    const ERC20Mock = await ethers.getContractFactory("ERC20Mock");
    token0 = await ERC20Mock.deploy("Token0", "TK0");
    await token0.deployed();
    token1 = await ERC20Mock.deploy("Token1", "TK1");
    await token1.deployed();

    // Deploy LiquidityPoolFactory
    LiquidityPoolFactory = await ethers.getContractFactory("LiquidityPoolFactory");
    factory = await LiquidityPoolFactory.deploy();
    await factory.deployed();
  });

  describe("Pool Creation", function () {
    it("Should create a new liquidity pool", async function () {
      const tx = await factory.createLiquidityPool(await token0.getAddress(), await token1.getAddress());
      const receipt = await tx.wait();
      
      // Get pool address from event
      const event = receipt.logs.find(log => {
        try {
          const parsed = factory.interface.parseLog({ topics: log.topics, data: log.data });
          return parsed.name === "LiquidityPoolCreated";
        } catch (e) {
          return false;
        }
      });
      const parsedEvent = factory.interface.parseLog({ topics: event.topics, data: event.data });
      const poolAddress = parsedEvent.args[0];
      
      // Verify pool exists
      const token0Address = await token0.getAddress();
      const token1Address = await token1.getAddress();
      expect(await factory.liquidityPools(token0Address, token1Address))
        .to.equal(poolAddress);
      expect(await factory.liquidityPools(token1Address, token0Address))
        .to.equal(poolAddress); // Reverse order should return same pool
    });

    it("Should revert when creating pool with same tokens", async function () {
      const token0Address = await token0.getAddress();
      await expect(factory.createLiquidityPool(token0Address, token0Address))
        .to.be.revertedWithCustomError(factory, "TokensMustBeDifferent");
    });

    it("Should revert when creating pool with zero address", async function () {
      const token1Address = await token1.getAddress();
      const zeroAddress = "0x0000000000000000000000000000000000000000";
      await expect(factory.createLiquidityPool(zeroAddress, token1Address))
        .to.be.revertedWithCustomError(factory, "InvalidTokenAddress");
    });

    it("Should revert when pool already exists", async function () {
      const token0Address = await token0.getAddress();
      const token1Address = await token1.getAddress();
      await factory.createLiquidityPool(token0Address, token1Address);
      await expect(factory.createLiquidityPool(token0Address, token1Address))
        .to.be.revertedWithCustomError(factory, "PoolAlreadyExists");
    });
  });

  describe("Pool Queries", function () {
    beforeEach(async function () {
      const token0Address = await token0.getAddress();
      const token1Address = await token1.getAddress();
      await factory.createLiquidityPool(token0Address, token1Address);
    });

    it("Should return correct pool count", async function () {
      const poolCount = await factory.createdPools();
      expect(poolCount).to.equal(1);
    });

    it("Should return all pools", async function () {
      const token0Address = await token0.getAddress();
      const token1Address = await token1.getAddress();
      const poolAddress = await factory.liquidityPools(token0Address, token1Address);
      expect(await factory.createdPools(0)).to.equal(poolAddress);
    });

    it("Should return same pool address regardless of token order", async function () {
      const token0Address = await token0.getAddress();
      const token1Address = await token1.getAddress();
      const pool01 = await factory.liquidityPools(token0Address, token1Address);
      const pool10 = await factory.liquidityPools(token1Address, token0Address);
      expect(pool01).to.equal(pool10);
    });
  });
});
