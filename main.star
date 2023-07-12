geth = import_module("github.com/kurtosis-tech/geth-package/lib/geth.star")
lighthouse = import_module("github.com/kurtosis-tech/lighthouse-package/lib/lighthouse.star")
mev_launcher = import_module("github.com/kurtosis-tech/mev-package/lib/mev_launcher.star")

network_params = json.decode(read_file("github.com/kurtosis-tech/geth-lighthouse-package/network_params.json"))

def run(plan):
    # Generate genesis, note EL and the CL needs the same timestamp to ensure that timestamp based forking works
    el_extra_params, mev_builder_image, validator_extra_params, beacon_extra_params = mev_launcher.get_mev_params()

    final_genesis_timestamp = geth.generate_genesis_timestamp()
    el_genesis_data = geth.generate_el_genesis_data(plan, final_genesis_timestamp, network_params, mev_builder_image, el_extra_params)

    # Run the nodes
    el_context = geth.run(plan, network_params, el_genesis_data)
    cl_context = lighthouse.run(plan, network_params, el_genesis_data, final_genesis_timestamp, el_context, beacon_extra_params, validator_extra_params)

    output = mev_launcher.launch_mev(plan, el_context, cl_context, network_params)

    return output
