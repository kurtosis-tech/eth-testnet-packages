PACKAGE_PATH = "github.com/kurtosis-tech/eth-testnet-packages/geth-lighthouse"
NETWORK_PARAM_JSON_FILE = PACKAGE_PATH+"/network_params.json"

geth = import_module(PACKAGE_PATH+"/geth-package/geth.star")
lighthouse = import_module(PACKAGE_PATH+"/lighthouse-package/lighthouse.star")


def run(plan):
    network_params = json.decode(read_file(NETWORK_PARAM_JSON_FILE))

    # Generate genesis, note EL and the CL needs the same timestamp to ensure that timestamp based forking works
    final_genesis_timestamp = geth.generate_genesis_timestamp(network_params["num_participants"])
    el_genesis_data = geth.generate_el_genesis_data(plan, final_genesis_timestamp, network_params)

    # Run the nodes
    el_context = geth.run(plan, network_params, el_genesis_data)
    lighthouse.run(plan, network_params, final_genesis_timestamp, el_genesis_data, el_context)

    return
