# Imports
geth = import_module("github.com/kurtosis-tech/eth-testnet-packages/geth-lighthouse-package/geth-package/geth.star")
lighthouse = import_module("github.com/kurtosis-tech/eth-testnet-packages/geth-lighthouse-package/lighthouse-package/lighthouse.star")

# Example data:
NUM_PARTICIPANTS = 2

CL_GENESIS_DATA_GENERATION_TIME = 5 * time.second
CL_NODE_STARTUP_TIME = 5 * time.second

def run(plan):
    # Read network params:
    NETWORK_PARAMS = read_file("github.com/kurtosis-tech/geth-lighthouse-package/network_params.json")
    # Generate genesis (optional)
    final_genesis_timestamp = (time.now() + CL_GENESIS_DATA_GENERATION_TIME + NUM_PARTICIPANTS * CL_NODE_STARTUP_TIME).unix
    el_genesis_data = geth.generate_el_genesis_data(plan, final_genesis_timestamp, NETWORK_PARAMS)

    # Run the nodes
    el_context = geth.run(plan, NETWORK_PARAMS, el_genesis_data)
    lighthouse.run(plan, NETWORK_PARAMS, NUM_PARTICIPANTS, final_genesis_timestamp, el_genesis_data, el_context)
    return


