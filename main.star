geth_mod       = import_module("github.com/kurtosis-tech/geth-package/lib/geth.star")
lighthouse_mod = import_module("github.com/kurtosis-tech/lighthouse-package/lib/lighthouse.star")

def run(plan):
    # ── hard‑coded params ──
    TAX_RATE         = 5
    TREASURY_ADDRESS = "0xFacaDE0000000000000000000000000000001234"

    # Load the genesis.json that sits next to this script
    genesis_content = plan.read_package_file("genesis.json")

    # Timestamp for CL
    genesis_ts = geth_mod.generate_genesis_timestamp()

    # ── Execution layer ──
    el_node = geth_mod.add_geth_node(
        plan            = plan,
        name            = "el-0",
        genesis_content = genesis_content,          # << no more write_file
        geth_image      = "rabidev/geth-tax:latest",
        extra_geth_args = [
            "--taxEnabled",      "true",
            "--taxRate",         str(TAX_RATE),
            "--treasuryAddress", TREASURY_ADDRESS,
        ],
    )

    # ── Consensus layer ──
    lighthouse_mod.add_lighthouse_node(
        plan              = plan,
        name              = "cl-0",
        el_node_rpc       = el_node.get_el_rpc_url(),
        genesis_timestamp = genesis_ts,
    )

    plan.print("EL‑RPC: " + el_node.get_el_rpc_url())

