::  opa-get-marine-fuels: fetch marine fuel prices by port and fuel type
::
/-  mcp, spider
/+  io=strandio
=,  strand-fail=strand-fail:strand:spider
^-  tool:mcp
:*  'opa-get-marine-fuels'
    'Get latest marine fuel prices. Optionally filter by port and fuel type.'
    %-  my
    :~  ['port' [%string 'Port name (optional, e.g. singapore, rotterdam, fujairah)']]
        ['fuel_type' [%string 'Fuel type (optional, e.g. VLSFO, HSFO, MGO)']]
    ==
    ~
::
    ^-  thread-builder:tool:mcp
    |=  args=(map name:parameter:tool:mcp argument:tool:mcp)
    =/  m  (strand:spider ,vase)
    ^-  form:m
    =/  port-arg=(unit argument:tool:mcp)  (~(get by args) 'port')
    =/  fuel-arg=(unit argument:tool:mcp)  (~(get by args) 'fuel_type')
    ::  GET /v1/marine-fuels/latest[?port={port}][&fuel_type={fuel_type}]
    ::
    =/  url=tape
      ?~  port-arg
        ?~  fuel-arg
          "https://api.oilpriceapi.com/v1/marine-fuels/latest"
        ?>  ?=([%string @t] u.fuel-arg)
        (weld "https://api.oilpriceapi.com/v1/marine-fuels/latest?fuel_type=" (trip p.u.fuel-arg))
      ?>  ?=([%string @t] u.port-arg)
      ?~  fuel-arg
        (weld "https://api.oilpriceapi.com/v1/marine-fuels/latest?port=" (trip p.u.port-arg))
      ?>  ?=([%string @t] u.fuel-arg)
      :(weld "https://api.oilpriceapi.com/v1/marine-fuels/latest?port=" (trip p.u.port-arg) "&fuel_type=" (trip p.u.fuel-arg))
    ::  load API key
    ::
    ;<  =bowl:rand  bind:m  get-bowl:io
    ;<  =cage  bind:m
      (read-file:io [our.bowl q.byk.bowl da+now.bowl] /dat/api-key/hoon)
    =/  api-key=@t  !<(@t q.cage)
    ?:  =(api-key 'YOUR_API_KEY_HERE')
      (strand-fail %no-api-key-configured ~)
    ::  fetch from API
    ::
    =/  =request:http
      :^  %'GET'  (crip url)
        ~[['Authorization' (crip (weld "Token " (trip api-key)))] ['Accept' 'application/json']]
      ~
    ;<  ~  bind:m  (send-request:io request)
    ;<  =client-response:iris  bind:m  take-client-response:io
    ?>  ?=(%finished -.client-response)
    ?.  =(2 (div status-code.response-header.client-response 100))
      =/  code=@ud  status-code.response-header.client-response
      %-  pure:m
      !>  ^-  json
      %-  pairs:enjs:format
      :~  ['type' s+'text']
          :-  'text'
          :-  %s
          %-  crip
          ?:  =(403 code)
            "Error: 403 Forbidden. This endpoint requires a premium OilpriceAPI key. Upgrade at https://www.oilpriceapi.com"
          ?:  =(401 code)
            "Error: 401 Unauthorized. Your API key may be invalid. Set a new one with opa-set-api-key."
          ?:  =(429 code)
            "Error: 429 Rate limit exceeded. The free tier allows 200 requests/month."
          ?:  =(404 code)
            "Error: 404 Not found. The requested resource does not exist."
          (weld "Error: HTTP " (weld (scow %ud code) " from OilpriceAPI."))
      ==
    ;<  body=cord  bind:m  (extract-body:io client-response)
    =/  jon=(unit json)  (de:json:html body)
    ?~  jon  (strand-fail %json-parse-error ~)
    %-  pure:m
    !>  ^-  json
    %-  pairs:enjs:format
    :~  ['type' s+'text']
        ['text' s+(en:json:html u.jon)]
    ==
==
