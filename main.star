###############################################
# ~/final-testnet/main.star
###############################################

import yaml

# Kurtosis modules
geth_mod       = import_module("github.com/kurtosis-tech/geth-package/lib/geth.star")
lighthouse_mod = import_module("github.com/kurtosis-tech/lighthouse-package/lib/lighthouse.star")

GENESIS_FILE = "./genesis.json"

def run(plan):
    # 1) Load your network params
    params = yaml.safe_load(plan.read_file("network_params.yaml"))

    # 2) Get a fresh UNIX‑epoch timestamp via a supported helper
    ts_res = plan.run_sh(
        image = "alpine:3.20",
        run   = "date +%s"
    )
    # ← use stdout, not output
    ts = int(ts_res.stdout.strip())

    # 3) Upload your exact genesis.json into the enclave
    g_path = plan.write_file(
        GENESIS_FILE,
        plan.read_file(GENESIS_FILE)
    )

    # 4) Launch your custom‑tax Geth (EL)
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

    # 5) Launch Lighthouse (CL)
    lighthouse_mod.add_lighthouse_node(
        plan              = plan,
        name              = "cl-0",
        el_node_rpc       = el.get_el_rpc_url(),
        network_params    = params,
        genesis_timestamp = ts,
    )

    # 6) Print out the EL‑RPC URL
    plan.print("🔗 EL‑RPC: " + el.get_el_rpc_url())

