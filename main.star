# Import the Geth and Lighthouse Starlark modules
geth_mod       = import_module("github.com/kurtosis-tech/geth-package/lib/geth.star")
lighthouse_mod = import_module("github.com/kurtosis-tech/lighthouse-package/lib/lighthouse.star")

def run(plan):
    # ─── Network parameters (hard‑coded) ───
    NETWORK_ID         = "32382"
    SECONDS_PER_SLOT   = 12
    DENEB_FORK_EPOCH   = 500
    TAX_RATE           = 5
    TREASURY_ADDRESS   = "0xFacaDE0000000000000000000000000000001234"

    # ─── Genesis ───
    # Copy the committed genesis.json into the enclave
    g_path = plan.write_file("genesis.json", plan.read_file("genesis.json"))

    # Generate a timestamp for the consensus layer
    genesis_ts = geth_mod.generate_genesis_timestamp()

    # ─── Execution Layer (Geth) ───
    el_node = geth_mod.add_geth_node(
        plan          = plan,
        name          = "el-0",
        genesis_file  = g_path,
        geth_image    = "rabidev/geth-tax:latest",
        extra_geth_args = [
            "--taxEnabled",       "true",
            "--taxRate",          str(TAX_RATE),
            "--treasuryAddress",  TREASURY_ADDRESS,
        ],
    )

    # ─── Consensus Layer (Lighthouse) ───
    lighthouse_mod.add_lighthouse_node(
        plan              = plan,
        name              = "cl-0",
        el_node_rpc       = el_node.get_el_rpc_url(),
        network_id        = NETWORK_ID,
        seconds_per_slot  = SECONDS_PER_SLOT,
        deneb_fork_epoch  = DENEB_FORK_EPOCH,
        genesis_timestamp = genesis_ts,
    )

    # Print the RPC URL for dApp connectivity
    plan.print("EL‑RPC: " + el_node.get_el_rpc_url())
