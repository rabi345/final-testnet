###############################################
# ~/final-testnet/main.star
###############################################

geth_mod       = import_module("github.com/kurtosis-tech/geth-package@v0.15.3/lib/geth.star")
lighthouse_mod = import_module("github.com/kurtosis-tech/lighthouse-package@v0.14.0/lib/lighthouse.star")

GENESIS_FILE = "genesis.json"
GETH_IMAGE   = "rabidev/geth-tax:latest"

def run(plan):
    params = {
        "network_id":       "32382",
        "seconds_per_slot": 12,
        "deneb_fork_epoch": 500,
        "tax_enabled":      True,
        "tax_rate":         5,
        "treasury_address": "0xFacaDE0000000000000000000000000000001234",
    }

    ts_res = plan.run_python(
        run = "import time, json, sys; json.dump(int(time.time()), sys.stdout)"
    )
    ts = int(ts_res.output)

    genesis_bytes = plan.read_file(GENESIS_FILE)
    g_path = plan.write_file(GENESIS_FILE, genesis_bytes)

    el = geth_mod.add_geth_node(
        plan          = plan,
        name          = "el-0",
        genesis_file  = g_path,
        geth_image    = GETH_IMAGE,
        extra_geth_args = [
            "--taxEnabled",     "true",
            "--taxRate",        str(params["tax_rate"]),
            "--treasuryAddress", params["treasury_address"],
        ],
    )

    lighthouse_mod.add_lighthouse_node(
        plan              = plan,
        name              = "cl-0",
        el_node_rpc       = el.get_el_rpc_url(),
        network_params    = params,
        genesis_timestamp = ts,
    )

    plan.print("🔗 EL‑RPC: " + el.get_el_rpc_url())

