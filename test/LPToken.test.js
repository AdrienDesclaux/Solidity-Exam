const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("LPToken", function () {
  let LPToken;
  let lpToken;
  let owner;
  let addr1;
  let addr2;
  let liquidityPool;

  beforeEach(async function () {
    [owner, addr1, addr2, liquidityPool] = await ethers.getSigners();

    // Deploy LPToken contract
    LPToken = await ethers.getContractFactory("LPToken");
    lpToken = await LPToken.deploy("LP Token", "LPT", liquidityPool.address);
  });

  describe("Deployment", function () {
    it("Should set the right liquidity pool address", async function () {
      expect(await lpToken.liquidityPool()).to.equal(liquidityPool.address);
    });

    it("Should set the correct name and symbol", async function () {
      expect(await lpToken.name()).to.equal("LP Token");
      expect(await lpToken.symbol()).to.equal("LPT");
    });
  });

  describe("Minting and Burning", function () {
    it("Should allow liquidity pool to mint tokens", async function () {
      const amount = ethers.parseEther("100");
      
      await expect(lpToken.connect(liquidityPool).mintLP(addr1.address, amount))
        .to.emit(lpToken, "LPTokenMinted")
        .withArgs(addr1.address, amount);
      
      expect(await lpToken.balanceOf(addr1.address)).to.equal(amount);
    });

    it("Should prevent non-liquidity pool from minting tokens", async function () {
      const amount = ethers.parseEther("100");
      
      await expect(lpToken.connect(addr1).mintLP(addr2.address, amount))
        .to.be.revertedWithCustomError(lpToken, "Unauthorized");
    });

    it("Should allow liquidity pool to burn tokens", async function () {
      const amount = ethers.parseEther("100");
      
      // First mint some tokens
      await lpToken.connect(liquidityPool).mintLP(addr1.address, amount);
      
      // Then burn them
      await expect(lpToken.connect(liquidityPool).burnLP(addr1.address, amount))
        .to.emit(lpToken, "LPTokenBurned")
        .withArgs(addr1.address, amount);
      
      expect(await lpToken.balanceOf(addr1.address)).to.equal(0);
    });

    it("Should prevent non-liquidity pool from burning tokens", async function () {
      const amount = ethers.parseEther("100");
      
      // First mint some tokens
      await lpToken.connect(liquidityPool).mintLP(addr1.address, amount);
      
      // Try to burn them from non-liquidity pool address
      await expect(lpToken.connect(addr1).burnLP(addr1.address, amount))
        .to.be.revertedWithCustomError(lpToken, "Unauthorized");
    });
  });

  describe("Constructor", function () {
    it("Should revert if liquidity pool address is zero", async function () {
      const LPToken = await ethers.getContractFactory("LPToken");
      await expect(LPToken.deploy("LP Token", "LPT", "0x0000000000000000000000000000000000000000"))
        .to.be.revertedWithCustomError(LPToken, "InvalidAddress");
    });
  });
});
