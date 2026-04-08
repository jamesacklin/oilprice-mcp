::  opa-compare-prices: compare current prices across multiple commodities
::
/-  mcp, spider
/+  io=strandio
=,  strand-fail=strand-fail:strand:spider
^-  tool:mcp
:*  'opa-compare-prices'
    'Fetch all current commodity prices. Specify which commodities you want compared so the results can be filtered and analyzed.'
    %-  my
    :~  ['commodities' [%string 'Comma-separated commodity names of interest (e.g. brent, wti, natural gas). All prices returned; use this to indicate focus.']]
    ==
    ~['commodities']
::
    ^-  thread-builder:tool:mcp
    |=  args=(map name:parameter:tool:mcp argument:tool:mcp)
    =/  m  (strand:spider ,vase)
    ^-  form:m
    =/  com-arg=(unit argument:tool:mcp)  (~(get by args) 'commodities')
    ?~  com-arg  (strand-fail %missing-commodities ~)
    ?>  ?=([%string @t] u.com-arg)
    =/  requested=tape  (trip p.u.com-arg)
    ::  GET /v1/prices/all -- fetch everything, let caller filter
    ::
    =/  url=tape  "https://api.oilpriceapi.com/v1/prices/all"
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
    =/  prefix=tape  :(weld "Requested commodities: " requested ". All current prices: ")
    =/  result=tape  (weld prefix (trip (en:json:html u.jon)))
    %-  pure:m
    !>  ^-  json
    %-  pairs:enjs:format
    :~  ['type' s+'text']
        ['text' s+(crip result)]
    ==
==
