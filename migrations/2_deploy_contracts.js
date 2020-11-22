const KugulaToken = artifacts.require('KugulaToken');

module.exports = async function(deployer, network, accounts) {
  // Deploy Token
  await deployer.deploy(KugulaToken)
  const kugulaToken = await KugulaToken.deployed()
}