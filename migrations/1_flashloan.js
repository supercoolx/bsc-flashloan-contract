const PancakeFlashSwap = artifacts.require("PancakeFlashSwap");

module.exports = async function (deployer) {
	await deployer.deploy(PancakeFlashSwap);
};
