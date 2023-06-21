# Imports
geth = import_module("github.com/kurtosis-tech/eth-testnet-packages/geth-lighthouse/geth-package/geth.star")
lighthouse = import_module("github.com/kurtosis-tech/eth-testnet-packages/geth-lighthouse/lighthouse-package/lighthouse.star")
genesis_constants = import_module("github.com/kurtosis-tech/eth-network-package/src/prelaunch_data_generator/genesis_constants/genesis_constants.star")

# Example data:
NUM_PARTICIPANTS = 2
NETWORK_PARAMS = {
    "preregistered_validator_keys_mnemonic": "giant issue aisle success illegal bike spike question tent bar rely arctic volcano long crawl hungry vocal artwork sniff fantasy very lucky have athlete",
    "num_validator_keys_per_node": 64,
    "network_id": "3151908",
    "deposit_contract_address": "0x4242424242424242424242424242424242424242",
    "seconds_per_slot": 12,
    "genesis_delay": 120,
    "capella_fork_epoch": 5
}

CL_GENESIS_DATA_GENERATION_TIME = 5 * time.second
CL_NODE_STARTUP_TIME = 5 * time.second

def run(plan):
    # Generate genesis (optional)
    final_genesis_timestamp = (time.now() + CL_GENESIS_DATA_GENERATION_TIME + NUM_PARTICIPANTS * CL_NODE_STARTUP_TIME).unix
    el_genesis_data = geth.generate_el_genesis_data(plan, final_genesis_timestamp, NETWORK_PARAMS)

    # Run the nodes
    el_context = geth.run(plan, NETWORK_PARAMS, el_genesis_data)
    lighthouse.run(plan, NETWORK_PARAMS, NUM_PARTICIPANTS, final_genesis_timestamp, el_genesis_data, el_context)
    return


