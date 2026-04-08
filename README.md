# OilpriceAPI MCP Server for Urbit

A standalone [Model Context Protocol](https://modelcontextprotocol.io) server running as a Gall agent on Urbit, providing real-time oil, gas, and energy commodity data from [Oil Price API](https://www.oilpriceapi.com).

## Setup

### 1. Install the desk

If you received this desk from a remote ship:

```
|install ~sampel-palnet %oilprice
```

If building locally, commit and install:

```
|commit %oilprice
|install our %oilprice
```

The agent binds to `/mcp/oilpriceapi` on Eyre.

### 2. Set your API key

Get a free API key at [oilpriceapi.com](https://www.oilpriceapi.com) (200 requests/month on the free tier).

**Option A — via MCP tool call:**

Use the `opa-set-api-key` tool from any connected MCP client:

```json
{
  "method": "tools/call",
  "params": {
    "name": "opa-set-api-key",
    "arguments": { "api_key": "your-key-here" }
  }
}
```

**Option B — edit the key file on the mounted desk:**

```
|mount %oilprice
```

Then write your key as a Hoon cord literal to `zod/oilprice/lib/oilprice-key.hoon`:

```hoon
'your-key-here'
```

And commit:

```
|commit %oilprice
```

### 3. Connect an MCP client

The server uses MCP Streamable HTTP transport. You need an authenticated Eyre session cookie.

**Get your session cookie:**

```bash
curl -c - -X POST https://your-ship.tlon.network/~/login \
  -d "password=$(cat your-code)"
```

This returns a cookie like `urbauth-~your-ship=0v6.abcde...`.

**Claude Code** (`~/.claude/settings.json`):

```json
{
  "mcpServers": {
    "oilprice": {
      "type": "url",
      "url": "https://your-ship.tlon.network/mcp/oilpriceapi",
      "headers": {
        "Cookie": "urbauth-~your-ship=SESSION_COOKIE"
      }
    }
  }
}
```

**Claude Desktop** (`claude_desktop_config.json`):

```json
{
  "mcpServers": {
    "oilprice": {
      "transport": {
        "type": "streamable-http",
        "url": "https://your-ship.tlon.network/mcp/oilpriceapi",
        "headers": {
          "Cookie": "urbauth-~your-ship=SESSION_COOKIE"
        }
      }
    }
  }
}
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
- **API key**: stored as a Hoon cord literal in `/lib/oilprice-key.hoon`
- **Tools**: file-based at `/fil/oilprice/tools/`, auto-installed on agent init

Each tool runs as a Khan thread that makes an authenticated HTTP request to `api.oilpriceapi.com` via the Iris vane, parses the JSON response, and returns it to the MCP client.

## License

MIT
