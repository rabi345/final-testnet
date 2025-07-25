# --- main.star (drop‑in replacement) ---------------------------------
geth_mod       = import_module("github.com/kurtosis-tech/geth-package/lib/geth.star")
lighthouse_mod = import_module("github.com/kurtosis-tech/lighthouse-package/lib/lighthouse.star")

def run(plan):
    # ── network & tax params ─────────────────────────────────────────
    NETWORK_ID        = "32382"
    TAX_RATE          = 5           # 5 %
    TREASURY_ADDRESS  = "0xFacaDE0000000000000000000000000000001234"

    # ── build an EL genesis blob entirely in memory ─────────────────
    ts          = geth_mod.generate_genesis_timestamp()
    el_genesis  = geth_mod.generate_el_genesis_data(
        plan             = plan,
        genesis_timestamp= ts,
        network_id       = NETWORK_ID,
        tax_enabled      = True,
        tax_rate         = TAX_RATE,
        treasury_address = TREASURY_ADDRESS,
    )

    # ── Execution‑layer node (your patched Geth) ────────────────────
    el = geth_mod.add_geth_node(
        plan         = plan,
        name         = "el-0",
        genesis_data = el_genesis,            # << no file ops
        geth_image   = "rabidev/geth-tax:latest",
    )

    # ── Consensus‑layer node (Lighthouse) ───────────────────────────
    lighthouse_mod.add_lighthouse_node(
        plan              = plan,
        name              = "cl-0",
        el_node_rpc       = el.get_el_rpc_url(),
        genesis_timestamp = ts,
    )

    plan.print("EL‑RPC: " + el.get_el_rpc_url())
# --------------------------------------------------------------------

