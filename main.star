###########################################
#  ~/final-testnet/main.star             #
###########################################

load("yaml", "safe_load")

# Import the official Kurtosis modules
geth_mod       = import_module("github.com/kurtosis-tech/geth-package/lib/geth.star")
lighthouse_mod = import_module("github.com/kurtosis-tech/lighthouse-package/lib/lighthouse.star")

# Read your network parameters from the committed YAML
with open("./network_params.yaml") as f:
    params = safe_load(f)

# Path to the genesis file you committed
GENESIS_FILE = "./genesis.json"

def run(plan):
    # 1) Generate a UNIX‐epoch timestamp via a supported helper
    #    (avoid the unsupported time.now())
    ts_res = plan.run_sh(
        image = "alpine:3.20",
        run   = "date +%s"
    )
    ts = int(ts_res.output.strip())

    # 2) Upload your exact genesis.json into the enclave
    g_path = plan.write_file(
        GENESIS_FILE,
        plan.read_file(GENESIS_FILE)
    )

    # 3) Launch your custom‐tax Geth node
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

    # 4) Launch a Lighthouse consensus node pointing at your EL
    lighthouse_mod.add_lighthouse_node(
        plan              = plan,
        name              = "cl-0",
        el_node_rpc       = el.get_el_rpc_url(),
        network_params    = params,
        genesis_timestamp = ts,
    )

    # 5) Print out the final RPC URL for you to copy/paste
    plan.print("🔗  EL‑RPC: " + el.get_el_rpc_url())

