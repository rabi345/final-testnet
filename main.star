# main.star  ── drop‑in replacement
geth_mod       = import_module("github.com/kurtosis-tech/geth-package/lib/geth.star")
lighthouse_mod = import_module("github.com/kurtosis-tech/lighthouse-package/lib/lighthouse.star")

def run(plan):
    TAX_RATE         = 5
    TREASURY_ADDRESS = "0xFacaDE0000000000000000000000000000001234"

    # 1) Grab genesis.json that lives in the package directory
    genesis_content = plan.read_file("genesis.json")

    # 2) Timestamp for the consensus layer
    ts = geth_mod.generate_genesis_timestamp()

    # 3) Execution layer (your custom Geth)
    el = geth_mod.add_geth_node(
        plan            = plan,
        name            = "el-0",
        genesis_content = genesis_content,
        geth_image      = "rabidev/geth-tax:latest",
        extra_geth_args = [
            "--taxEnabled",      "true",
            "--taxRate",         str(TAX_RATE),
            "--treasuryAddress", TREASURY_ADDRESS,
        ],
    )

    # 4) Consensus layer (Lighthouse)
    lighthouse_mod.add_lighthouse_node(
        plan              = plan,
        name              = "cl-0",
        el_node_rpc       = el.get_el_rpc_url(),
        genesis_timestamp = ts,
    )

    plan.print("EL‑RPC: " + el.get_el_rpc_url())

