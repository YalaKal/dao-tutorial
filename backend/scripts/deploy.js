const { CRYPTODEVS_NFT_CONTRACT_ADDRESS } = require('../constants')
const { ethers } = require( 'hardhat')

async function main() {
  const FakeNFTMarketplace = await ethers.getContractFactory("FakeNFTMarketplace")

  const fakeNFTMarketplace = await FakeNFTMarketplace.deploy()
  await fakeNFTMarketplace.deployed()

  console.log(`
    FakeNFTMarketplace deployed at: ${fakeNFTMarketplace.address}
  `)
  // Deploy the CryptoDevsDAO contract
  const CryptoDevsDAO = await ethers.getContractFactory("CryptoDevsDAO")
  const cryptoDevsDAO = await CryptoDevsDAO.deploy(
    fakeNFTMarketplace.address,
    CRYPTODEVS_NFT_CONTRACT_ADDRESS,
    {
      value: ethers.utils.parseEther("1")
    }
  );
  await cryptoDevsDAO.deployed()
  console.log(`CryptoDevsDAO deployed at: ${cryptoDevsDAO.address}`)

}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error)
    process.exit(1)
  })