const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("LiquidityPool", function () {
  let LiquidityPool;
  let pool;
  let token0;
  let token1;
  let owner;
  let addr1;
  let addr2;
  let treasury;

  beforeEach(async function () {
    [owner, addr1, addr2, treasury] = await ethers.getSigners();

    // Deploy mock ERC20 tokens
    const ERC20Mock = await ethers.getContractFactory("ERC20Mock");
    token0 = await ERC20Mock.deploy("Token0", "TK0");
    await token0.deployed();
    token1 = await ERC20Mock.deploy("Token1", "TK1");
    await token1.deployed();

    // Sort tokens by address
    if ((await token1.address).toLowerCase() < (await token0.address).toLowerCase()) {
      [token0, token1] = [token1, token0];
    }

    // Deploy LiquidityPool
    LiquidityPool = await ethers.getContractFactory("LiquidityPool");
    pool = await LiquidityPool.deploy(
      await token0.address,
      await token1.address,
      treasury.address,
      "LP Token",
      "LPT"
    );
    await pool.deployed();

    // Mint some tokens to addr1
    const amount = ethers.parseEther("1000");
    await token0.mint(addr1.address, amount);
    await token1.mint(addr1.address, amount);
    await token0.connect(addr1).approve(await pool.address, amount);
    await token1.connect(addr1).approve(await pool.address, amount);
  });

  describe("Deployment", function () {
    it("Should set the correct token addresses", async function () {
      expect(await pool.token0()).to.equal(await token0.address);
      expect(await pool.token1()).to.equal(await token1.address);
    });

    it("Should set the correct treasury address", async function () {
      expect(await pool.treasury()).to.equal(treasury.address);
    });
  });

  describe("Liquidity", function () {
    it("Should add initial liquidity correctly", async function () {
      const amount0 = ethers.parseEther("100");
      const amount1 = ethers.parseEther("100");

      await expect(pool.connect(addr1).addLiquidity(amount0, amount1))
        .to.emit(pool, "AddLiquidity")
        .withArgs(addr1.address, amount0, amount1);

      const lpBalance = await pool.balanceOf(addr1.address);
      expect(lpBalance).to.be.gt(0);
    });

    it("Should remove liquidity correctly", async function () {
      const amount0 = ethers.parseEther("100");
      const amount1 = ethers.parseEther("100");

      // First add liquidity
      await pool.connect(addr1).addLiquidity(amount0, amount1);
      const lpBalance = await pool.balanceOf(addr1.address);

      // Then remove it
      await expect(pool.connect(addr1).removeLiquidity(lpBalance))
        .to.emit(pool, "RemoveLiquidity")
        .withArgs(addr1.address, amount0, amount1);

      expect(await pool.balanceOf(addr1.address)).to.equal(0);
    });
  });

  describe("Swapping", function () {
    beforeEach(async function () {
      // Add initial liquidity
      const amount = ethers.parseEther("100");
      await pool.connect(addr1).addLiquidity(amount, amount);
    });

    it("Should swap tokens correctly", async function () {
      const swapAmount = ethers.parseEther("10");
      const expectedOutput = ethers.parseEther("9.8"); // Considering 2% total fees

      // Approve tokens for swap
      await token0.connect(addr1).approve(await pool.address, swapAmount);

      // Get initial balances
      const initialBalance1 = await token1.balanceOf(addr1.address);

      // Perform swap
      await expect(pool.connect(addr1).swap(0, expectedOutput))
        .to.emit(pool, "Swap")
        .withArgs(addr1.address, swapAmount, 0, 0, expectedOutput);

      // Check final balances
      const finalBalance1 = await token1.balanceOf(addr1.address);
      expect(finalBalance1 - initialBalance1).to.equal(expectedOutput);
    });

    it("Should collect fees correctly", async function () {
      const swapAmount = ethers.parseEther("10");
      const expectedOutput = ethers.parseEther("9.8");

      // Initial treasury balance
      const initialTreasuryBalance = await token0.balanceOf(treasury.address);

      // Perform swap
      await token0.connect(addr1).approve(await pool.address, swapAmount);
      await pool.connect(addr1).swap(0, expectedOutput);

      // Check treasury received its share of fees
      const finalTreasuryBalance = await token0.balanceOf(treasury.address);
      const treasuryFee = swapAmount * 1n / 100n; // 1% treasury fee
      expect(finalTreasuryBalance - initialTreasuryBalance).to.equal(treasuryFee);
    });

    it("Should revert on insufficient output amount", async function () {
      await expect(pool.connect(addr1).swap(0, 0))
        .to.be.revertedWithCustomError(pool, "InsufficientOutputAmount");
    });

    it("Should revert on insufficient liquidity", async function () {
      const hugeAmount = ethers.parseEther("1000000");
      await expect(pool.connect(addr1).swap(hugeAmount, 0))
        .to.be.revertedWithCustomError(pool, "InsufficientLiquidity");
    });
  });
});
