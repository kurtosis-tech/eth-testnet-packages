geth = import_module("github.com/kurtosis-tech/eth-testnet-packages/geth-lighthouse/geth-package/geth.star")
lighthouse = import_module("github.com/kurtosis-tech/eth-testnet-packages/geth-lighthouse/lighthouse-package/lighthouse.star")

NETWORK_PARAM_JSON_FILE = "github.com/kurtosis-tech/eth-testnet-packages/geth-lighthouse/network_params.json"


def run(plan):
    network_params = json.decode(read_file(NETWORK_PARAM_JSON_FILE))

    # Generate genesis, note EL and the CL needs the same timestamp to ensure that timestamp based forking works
    final_genesis_timestamp = geth.generate_genesis_timestamp()
    el_genesis_data = geth.generate_el_genesis_data(plan, final_genesis_timestamp, network_params)

    # Run the nodes
    el_context = geth.run(plan, network_params, el_genesis_data)
    lighthouse.run(plan, network_params, final_genesis_timestamp, el_genesis_data, el_context)

    return
