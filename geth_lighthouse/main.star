# Imports
static_files = import_module("github.com/kurtosis-tech/eth-network-package/static_files/static_files.star")
input_parser = import_module("github.com/kurtosis-tech/eth-network-package/package_io/input_parser.star")

geth = import_module("github.com/kurtosis-tech/eth-network-package/src/el/geth/geth_launcher.star")
lighthouse = import_module("github.com/kurtosis-tech/eth-network-package/src/cl/lighthouse/lighthouse_launcher.star")

genesis_constants = import_module(
    "github.com/kurtosis-tech/eth-network-package/src/prelaunch_data_generator/genesis_constants/genesis_constants.star")
el_genesis_data_generator = import_module(
    "github.com/kurtosis-tech/eth-network-package/src/prelaunch_data_generator/el_genesis/el_genesis_data_generator.star")
cl_genesis_data_generator = import_module(
    "github.com/kurtosis-tech/eth-network-package/src/prelaunch_data_generator/cl_genesis/cl_genesis_data_generator.star")
cl_validator_keystores = import_module(
    "github.com/kurtosis-tech/eth-network-package/src/prelaunch_data_generator/cl_validator_keystores/cl_validator_keystore_generator.star")

# Constants
EL_CLIENT_SERVICE_NAME_PREFIX = "el-client-"
CL_CLIENT_SERVICE_NAME_PREFIX = "cl-client-"
CL_GENESIS_DATA_GENERATION_TIME = 5 * time.second
CL_NODE_STARTUP_TIME = 5 * time.second
CL_CLIENT_CONTEXT_BOOTNODE = None
GLOBAL_LOG_LEVEL = ""
EL_CLIENT_LOG_LEVEL = "3"
EL_CLIENT_IMAGE = input_parser.DEFAULT_EL_IMAGES["geth"]


def run(plan, args):
    num_participants = 2
    final_genesis_timestamp = (
            time.now() + CL_GENESIS_DATA_GENERATION_TIME + num_participants * CL_NODE_STARTUP_TIME).unix
    network_params = {
        "preregistered_validator_keys_mnemonic": "giant issue aisle success illegal bike spike question tent bar rely arctic volcano long crawl hungry vocal artwork sniff fantasy very lucky have athlete",
        "num_validator_keys_per_node": 64,
        "network_id": "3151908",
        "deposit_contract_address": "0x4242424242424242424242424242424242424242",
        "seconds_per_slot": 12,
        "genesis_delay": 120,
        "capella_fork_epoch": 5
    }
    el_genesis_data = generate_el_genesis_data(plan, final_genesis_timestamp, network_params)
    el_context = run_geth(plan, network_params, el_genesis_data)
    run_lighthouse(plan, args, network_params, num_participants, final_genesis_timestamp, el_genesis_data, el_context)


def generate_el_genesis_data(plan, final_genesis_timestamp, network_params):
    el_genesis_generation_config_template = read_file(static_files.EL_GENESIS_GENERATION_CONFIG_TEMPLATE_FILEPATH)
    el_genesis_data = el_genesis_data_generator.generate_el_genesis_data(
        plan,
        el_genesis_generation_config_template,
        final_genesis_timestamp,
        network_params["network_id"],
        network_params["deposit_contract_address"],
        network_params["genesis_delay"],
        network_params["capella_fork_epoch"],
    )
    return el_genesis_data


def run_geth(plan, network_params, el_genesis_data):
    geth_prefunded_keys_artifact_name = plan.upload_files(
        static_files.GETH_PREFUNDED_KEYS_DIRPATH,
        name="geth-prefunded-keys",
    )
    launcher = geth.new_geth_launcher(
        network_params["network_id"],
        el_genesis_data,
        geth_prefunded_keys_artifact_name,
        genesis_constants.PRE_FUNDED_ACCOUNTS
    )
    service_name = "{0}{1}".format(EL_CLIENT_SERVICE_NAME_PREFIX, 0)
    return geth.launch(
        plan,
        launcher,
        service_name,
        EL_CLIENT_IMAGE,
        EL_CLIENT_LOG_LEVEL,
        GLOBAL_LOG_LEVEL,
        # If empty, the node will be launched as a bootnode
        [],  # existing_el_clients
        [],  #extra_params
    )


def run_lighthouse(plan, args, network_params, num_participants, final_genesis_timestamp, el_genesis_data, el_context):
    genesis_generation_config_yml_template = read_file(static_files.CL_GENESIS_GENERATION_CONFIG_TEMPLATE_FILEPATH)
    genesis_generation_mnemonics_yml_template = read_file(
        static_files.CL_GENESIS_GENERATION_MNEMONICS_TEMPLATE_FILEPATH)

    service_name = "{0}{1}".format(CL_CLIENT_SERVICE_NAME_PREFIX, 0)
    client_image = input_parser.DEFAULT_CL_IMAGES["lighthouse"]
    client_log_level = "debug"

    cl_validator_data = cl_validator_keystores.generate_cl_validator_keystores(
        plan,
        network_params["preregistered_validator_keys_mnemonic"],
        num_participants,
        network_params["num_validator_keys_per_node"],
    )

    total_number_of_validator_keys = network_params["num_validator_keys_per_node"] * num_participants

    cl_genesis_data = cl_genesis_data_generator.generate_cl_genesis_data(
        plan,
        genesis_generation_config_yml_template,
        genesis_generation_mnemonics_yml_template,
        el_genesis_data,
        final_genesis_timestamp,
        network_params["network_id"],
        network_params["deposit_contract_address"],
        network_params["seconds_per_slot"],
        network_params["preregistered_validator_keys_mnemonic"],
        total_number_of_validator_keys,
        network_params["genesis_delay"],
        network_params["capella_fork_epoch"],
    )

    preregistered_validator_keys_for_nodes = cl_validator_data.per_node_keystores
    new_cl_node_validator_keystores = preregistered_validator_keys_for_nodes[0]

    launcher = lighthouse.new_lighthouse_launcher(cl_genesis_data)
    lighthouse.launch(
        plan,
        launcher,
        service_name,
        client_image,
        client_log_level,
        GLOBAL_LOG_LEVEL,
        CL_CLIENT_CONTEXT_BOOTNODE,
        el_context,  # <- if you have multiple nodes, include their contexts here
        new_cl_node_validator_keystores,
        [],
        [],
    )
