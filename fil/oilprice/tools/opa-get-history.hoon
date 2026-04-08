::  opa-get-history: fetch historical prices for a commodity over a time period
::
/-  mcp, spider
/+  io=strandio
=,  strand-fail=strand-fail:strand:spider
^-  tool:mcp
:*  'opa-get-history'
    'Get historical prices for a commodity over a time period.'
    %-  my
    :~  ['commodity' [%string 'Commodity name or API code (e.g. brent, wti, natural gas, diesel, gasoline, gold)']]
        ['period' [%string 'Time period: day, week, month, or year']]
    ==
    ~['commodity' 'period']
::
    ^-  thread-builder:tool:mcp
    |=  args=(map name:parameter:tool:mcp argument:tool:mcp)
    =/  m  (strand:spider ,vase)
    ^-  form:m
    =/  com-arg=(unit argument:tool:mcp)  (~(get by args) 'commodity')
    ?~  com-arg  (strand-fail %missing-commodity ~)
    ?>  ?=([%string @t] u.com-arg)
    =/  per-arg=(unit argument:tool:mcp)  (~(get by args) 'period')
    ?~  per-arg  (strand-fail %missing-period ~)
    ?>  ?=([%string @t] u.per-arg)
    =/  aliases=(map tape tape)
      %-  my:nl
      :~  ["brent" "BRENT_CRUDE_USD"]
          ["wti" "WTI_USD"]
          ["natural gas" "NATURAL_GAS_USD"]
          ["diesel" "DIESEL_USD"]
          ["gasoline" "GASOLINE_RBOB_USD"]
          ["jet fuel" "JET_FUEL_USD"]
          ["gold" "GOLD_USD"]
          ["silver" "SILVER_USD"]
          ["coal" "COAL_USD"]
          ["heating oil" "HEATING_OIL_USD"]
          ["rbob" "GASOLINE_RBOB_USD"]
          ["urals" "URALS_USD"]
          ["dubai" "DUBAI_CRUDE_USD"]
          ["carbon" "CARBON_EUR"]
          ["uk gas" "UK_GAS_GBP"]
          ["ttf" "TTF_EUR"]
      ==
    =/  input=tape  (cass (trip p.u.com-arg))
    =/  code=tape
      =/  hit=(unit tape)  (~(get by aliases) input)
      ?^  hit  u.hit
      (cuss input)
    =/  period=tape  (cass (trip p.u.per-arg))
    ::  GET /v1/prices/past_{period}?by_code={code}
    ::
    =/  url=tape  :(weld "https://api.oilpriceapi.com/v1/prices/past_" period "?by_code=" code)
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
      ~|  [%http-error status-code.response-header.client-response]
      (strand-fail %http-error ~)
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
