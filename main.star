import yaml
geth = import_module("github.com/kurtosis-tech/geth-package/lib/geth.star")
lighthouse = import_module("github.com/kurtosis-tech/lighthouse-package/lib/lighthouse.star")

params = yaml.safe_load(read_file("network_params.yaml"))

def run(plan):
    g_path = plan.write_file("genesis.json", read_file("genesis.json"))
    ts     = geth.generate_genesis_timestamp()

    el = geth.add_geth_node(
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

    lighthouse.add_lighthouse_node(
        plan              = plan,
        name              = "cl-0",
        el_node_rpc       = el.get_el_rpc_url(),
        network_params    = params,
        genesis_timestamp = ts,
    )

    plan.print("EL‑RPC: " + el.get_el_rpc_url())
