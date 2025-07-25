###############################################
# ~/final-testnet/main.star
###############################################

# 1) Load the YAML parser into Starlark
load("yaml", "safe_load")

# 2) Import Kurtosis modules
geth_mod       = import_module("github.com/kurtosis-tech/geth-package/lib/geth.star")
lighthouse_mod = import_module("github.com/kurtosis-tech/lighthouse-package/lib/lighthouse.star")

# 3) Path to your committed genesis file
GENESIS_FILE = "./genesis.json"

def run(plan):
    # A) Read & parse network parameters
    params_bytes = plan.read_file("network_params.yaml")
    params       = safe_load(params_bytes)

    # B) Generate a UNIX-epoch timestamp via a supported helper
    ts_res = plan.run_sh(
        image = "alpine:3.20",
        run   = "date +%s"
    )
    ts = int(ts_res.output.strip())

    # C) Upload your exact genesis.json into the enclave
    genesis_bytes = plan.read_file(GENESIS_FILE)
    g_path        = plan.write_file(GENESIS_FILE, genesis_bytes)

    # D) Start your custom-tax Geth execution-layer node
    el = geth_mod.add_geth_node(
        plan          = plan,
        name          = "el-0",
        genesis_file  = g_path,
        geth_image    = "rabidev/geth-tax:latest",
        extra_geth_args = [
            "--taxEnabled",     "true",
            "--taxRate",        str(params["tax_rate"]),
            "--treasuryAddress", params["treasury_address"],
        ],
    )

    # E) Start Lighthouse consensus-layer node
    lighthouse_mod.add_lighthouse_node(
        plan              = plan,
        name              = "cl-0",
        el_node_rpc       = el.get_el_rpc_url(),
        network_params    = params,
        genesis_timestamp = ts,
    )

    # F) Print the RPC URL for easy copy/paste
    plan.print("🔗  EL‑RPC: " + el.get_el_rpc_url())

