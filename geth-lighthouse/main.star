# Imports
geth = import_module("github.com/kurtosis-tech/eth-testnet-packages/geth-lighthouse/geth-package/geth.star")
lighthouse = import_module("github.com/kurtosis-tech/eth-testnet-packages/geth-lighthouse/lighthouse-package/lighthouse.star")

# Example data:
NUM_PARTICIPANTS = 2

CL_GENESIS_DATA_GENERATION_TIME = 5 * time.second
CL_NODE_STARTUP_TIME = 5 * time.second

def run(plan):
    # Read network params:
    network_params = json.decode(read_file("github.com/kurtosis-tech/eth-testnet-packages/geth-lighthouse/network_params.json"))

    #Generate genesis (optional)
    # We need to send the same genesis time to both the EL and the CL to ensure that timestamp based forking works as expected
    final_genesis_timestamp = (time.now() + CL_GENESIS_DATA_GENERATION_TIME + NUM_PARTICIPANTS * CL_NODE_STARTUP_TIME).unix
    el_genesis_data = geth.generate_el_genesis_data(plan, final_genesis_timestamp, network_params)

    # Run the nodes
    el_context = geth.run(plan, network_params, el_genesis_data)
    lighthouse.run(plan, network_params, NUM_PARTICIPANTS, final_genesis_timestamp, el_genesis_data, el_context)
    return


