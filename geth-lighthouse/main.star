PACKAGE_PATH = "github.com/kurtosis-tech/eth-testnet-packages/geth-lighthouse"
# Imports
geth = import_module(PACKAGE_PATH+"/geth-package/geth.star")
lighthouse = import_module(PACKAGE_PATH+"/lighthouse-package/lighthouse.star")

# Example data:
NUM_PARTICIPANTS = 1
NETWORK_PARAM_JSON_FILE = PACKAGE_PATH+"/network_params.json"

def run(plan):
    network_params = json.decode(read_file(NETWORK_PARAM_JSON_FILE))

    # Generate genesis, note we need to send the same genesis time to both the EL and the CL
    # to ensure that timestamp based forking works as expected
    final_genesis_timestamp = geth.generate_genesis_timestamp(NUM_PARTICIPANTS)
    el_genesis_data = geth.generate_el_genesis_data(plan, final_genesis_timestamp, network_params)

    # Run the nodes
    el_context = geth.run(plan, network_params, el_genesis_data)
    lighthouse.run(plan, network_params, NUM_PARTICIPANTS, final_genesis_timestamp, el_genesis_data, el_context)

    return
