###############################################
# ~/final-testnet/main.star
###############################################

# 1) Import the Kurtosis EL & CL modules
geth_mod       = import_module("github.com/kurtosis-tech/geth-package/lib/geth.star")
lighthouse_mod = import_module("github.com/kurtosis-tech/lighthouse-package/lib/lighthouse.star")

# 2) Path to your committed genesis snapshot
GENESIS_FILE = "genesis.json"

def run(plan):
    # 3) Hard‑coded network parameters (no YAML needed)
    params = {
        "network_id":        "32382",
        "seconds_per_slot":  12,
        "deneb_fork_epoch":  500,
        "tax_enabled":       True,
        "tax_rate":          5,    # 5%
        "treasury_address":  "0xFacaDE0000000000000000000000000000001234",
    }

    # 4) Get a UNIX‑epoch timestamp via a supported helper
    ts_res = plan.run_sh(
        image = "alpine:3.20",
        run   = "date +%s"
    )
    ts = int(ts_res.stdout.strip())

    # 5) Upload your exact genesis.json into the enclave
    g_path = plan.write_file(
        GENESIS_FILE,
        plan.read_file(GENESIS_FILE)
    )

    # 6) Launch your custom‑tax Geth (Execution Layer)
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

    # 7) Launch Lighthouse (Consensus Layer)
    lighthouse_mod.add_lighthouse_node(
        plan              = plan,
        name              = "cl-0",
        el_node_rpc       = el.get_el_rpc_url(),
        network_params    = params,
        genesis_timestamp = ts,
    )

    # 8) Print the RPC endpoint for you to copy/paste
    plan.print("🔗 EL‑RPC: " + el.get_el_rpc_url())

