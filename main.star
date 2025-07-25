load("yaml", "safe_load")
# import_module is a built‑in
geth_mod       = import_module("github.com/kurtosis-tech/geth-package/lib/geth.star")
lighthouse_mod = import_module("github.com/kurtosis-tech/lighthouse-package/lib/lighthouse.star")

def run(plan):
    # 1) Read params
    params = safe_load(plan.read_file("network_params.yaml"))

    # 2) Ship in the genesis.json you committed
    g_path = plan.write_file("genesis.json", plan.read_file("genesis.json"))

    # 3) Generate a timestamp for consensus layer
    ts = geth_mod.generate_genesis_timestamp()

    # 4) Start your custom‑tax Geth node
    el = geth_mod.add_geth_node(
        plan         = plan,
        name         = "el-0",
        genesis_file = g_path,
        geth_image   = "rabidev/geth-tax:latest",
        extra_geth_args = [
            "--taxEnabled",      "true",
            "--taxRate",         str(params["tax_rate"]),
            "--treasuryAddress", params["treasury_address"],
        ],
    )

    # 5) Start Lighthouse pointing at your EL
    lighthouse_mod.add_lighthouse_node(
        plan              = plan,
        name              = "cl-0",
        el_node_rpc       = el.get_el_rpc_url(),
        network_params    = params,
        genesis_timestamp = ts,
    )

    # 6) Print out the RPC URL for you to copy
    plan.print("EL‑RPC: " + el.get_el_rpc_url())
