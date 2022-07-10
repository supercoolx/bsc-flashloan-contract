const dotenv = require('dotenv');
const HDWalletProvider = require('@truffle/hdwallet-provider');

dotenv.config();

module.exports = {
	networks: {
		testbsc: {
			provider: () => new HDWalletProvider(process.env.PRIVATE_KEY, 'https://data-seed-prebsc-1-s1.binance.org:8545'),
			network_id: 97,
			skipDryRun: true,
			networkCheckTimeout: 1000000
		}
	},
	mocha: {
	},
	compilers: {
		solc: {
			version: "0.8.10"
		}
	},
	plugins: [
		'truffle-plugin-verify'
	],
	api_keys: {
		bscscan: process.env.BSCSCAN_KEY
	}
};
