# OilpriceAPI MCP Server for Urbit

A standalone [Model Context Protocol](https://modelcontextprotocol.io) server running as a Gall agent on Urbit, providing real-time oil, gas, and energy commodity data from [OilpriceAPI](https://www.oilpriceapi.com).

## Quick Start

There are two keys involved:

- **Urbit session cookie** — authenticates Claude to your ship's Eyre HTTP interface
- **OilpriceAPI key** — authenticates your ship to the OilpriceAPI data service

### Step 1: Install the desk on your ship

Clone this repo into your ship's pier directory and install:

```bash
# from your pier directory (e.g. ~/zod/)
cp -r /path/to/oilprice-mcp oilprice
```

Then in your ship's dojo:

```
|commit %oilprice
|install our %oilprice
```

Or install from a remote ship that distributes it:

```
|install ~sampel-palnet %oilprice
```

The agent binds to `/mcp/oilpriceapi` on Eyre automatically.

### Step 2: Get your Urbit session cookie

Run `+code` in your dojo to get your web login code, then authenticate:

```bash
curl -v -X POST https://your-ship.example.com/~/login \
  -d 'password=YOUR-CODE-HERE' \
  2>&1 | grep 'set-cookie'
```

Copy the cookie value — it looks like `urbauth-~your-ship=0v6.abcde.fghij...`

### Step 3: Connect Claude Code to your ship

Add this to `~/.claude.json`:

```json
{
  "mcpServers": {
    "oilprice": {
      "type": "http",
      "url": "https://your-ship.example.com/mcp/oilpriceapi",
      "headers": {
        "Cookie": "urbauth-~your-ship=0v6.abcde.fghij..."
      }
    }
  }
}
```

Restart Claude Code / Claude Desktop to pick up the new server.

### Step 4: Set your OilpriceAPI key

Get a free key at [oilpriceapi.com](https://www.oilpriceapi.com) (200 requests/month on the free tier).

Once Claude is connected to your ship, just ask it to set your key:

> "Set my OilpriceAPI key to abc123xyz"

Claude will call the `opa-set-api-key` tool, which writes the key to your ship. All other tools will use it automatically.

**Alternative** — set the key by hand on the mounted desk:

```
> |mount %oilprice
```

Write your key as a Hoon cord literal to `<pier>/oilprice/lib/oilprice-key.hoon`:

```hoon
'your-key-here'
```

Then commit:

```
> |commit %oilprice
```

## Tools

| Tool                      | Parameters            | Description                                   |
| ------------------------- | --------------------- | --------------------------------------------- |
| `opa-set-api-key`         | `api_key`             | Save your OilpriceAPI key                     |
| `opa-get-price`           | `commodity`           | Spot price for a commodity (supports aliases) |
| `opa-market-overview`     | —                     | All commodity prices                          |
| `opa-list-commodities`    | —                     | Available commodity codes                     |
| `opa-compare-prices`      | `commodities`         | Compare multiple commodities                  |
| `opa-get-history`         | `commodity`, `period` | Historical prices (day/week/month/year)       |
| `opa-get-futures`         | `contract`            | Front-month futures (BZ/CL)                   |
| `opa-get-futures-curve`   | `contract`            | Forward curve (BZ/CL)                         |
| `opa-get-marine-fuels`    | `port`?, `fuel_type`? | Bunker fuel prices                            |
| `opa-get-rig-counts`      | —                     | Baker Hughes US rig count                     |
| `opa-get-drilling`        | `region`?             | Regional drilling data                        |
| `opa-get-diesel-by-state` | `state`               | US retail diesel by state                     |
| `opa-get-storage`         | `facility`?           | Cushing/SPR inventory                         |
| `opa-get-opec-production` | —                     | OPEC production data                          |
| `opa-get-forecasts`       | —                     | EIA STEO forecasts                            |

### Commodity aliases

`opa-get-price` and `opa-get-history` accept natural language names:

| Alias                         | API Code            |
| ----------------------------- | ------------------- |
| brent, brent oil, brent crude | `BRENT_CRUDE_USD`   |
| wti, us oil, west texas       | `WTI_USD`           |
| natural gas, gas, nat gas     | `NATURAL_GAS_USD`   |
| diesel                        | `DIESEL_USD`        |
| gasoline, petrol              | `GASOLINE_USD`      |
| jet fuel, aviation fuel       | `JET_FUEL_USD`      |
| gold                          | `GOLD_USD`          |
| silver                        | `SILVER_FIX_USD`    |
| coal                          | `COAL_USD`          |
| heating oil                   | `HEATING_OIL_USD`   |
| rbob                          | `GASOLINE_RBOB_USD` |
| urals, russian oil            | `URALS_CRUDE_USD`   |
| dubai, dubai crude            | `DUBAI_CRUDE_USD`   |
| carbon, eu carbon             | `EU_CARBON_EUR`     |
| uk gas                        | `NATURAL_GAS_GBP`   |
| ttf, dutch ttf, european gas  | `DUTCH_TTF_EUR`     |

Or pass any raw API code directly (e.g. `BRENT_CRUDE_USD`).

## Architecture

- **Desk**: `%oilprice` — self-contained, no dependency on `%mcp`
- **Agent**: `%oilprice` — Gall agent handling MCP JSON-RPC over Streamable HTTP
- **Eyre path**: `/mcp/oilpriceapi`
- **API key**: stored in `/lib/oilprice-key.hoon`, set via `opa-set-api-key` tool or manual edit
- **Tools**: file-based at `/fil/oilprice/tools/`, auto-installed on agent init

Each tool runs as a Khan thread that makes an authenticated HTTP request to `api.oilpriceapi.com` via the Iris vane, parses the JSON response, and returns it to the MCP client.

## Session cookies

Urbit session cookies expire periodically. If Claude starts getting authentication errors, generate a fresh cookie (step 2) and update your settings.

## License

MIT
