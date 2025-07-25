###############################################
# ~/final-testnet/main.star
###############################################

# 1) Bring in the YAML helper
load("yaml", "safe_load")

# 2) Import Kurtosis EL & CL modules
geth_mod       = import_module("github.com/kurtosis-tech/geth-package/lib/geth.star")
lighthouse_mod = import_module("github.com/kurtosis-tech/lighthouse-package/lib/lighthouse.star")

# 3) Path to your committed genesis
GENESIS_FILE = "genesis.json"

def run(plan):
    # --- A) Read network parameters ---
    params = safe_load(plan.read_file("network_params.yaml"))

    # --- B) Generate a UNIX‑epoch timestamp ---
    ts_res = plan.run_sh(
        image = "alpine:3.20",
        run   = "date +%s"
    )
    ts = int(ts_res.stdout.strip())

    # --- C) Upload your exact genesis into the enclave ---
    g_path = plan.write_file(
        GENESIS_FILE,
        plan.read_file(GENESIS_FILE)
    )

    # --- D) Launch your custom‑tax Geth node (Execution Layer) ---
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

    # --- E) Launch Lighthouse (Consensus Layer) ---
    lighthouse_mod.add_lighthouse_node(
        plan              = plan,
        name              = "cl-0",
        el_node_rpc       = el.get_el_rpc_url(),
        network_params    = params,
        genesis_timestamp = ts,
    )

    # --- F) Print the RPC endpoint for easy copy/paste ---
    plan.print("🔗 EL‑RPC: " + el.get_el_rpc_url())

