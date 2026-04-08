::  opa-get-drilling: fetch latest drilling data, optionally by region
::
/-  mcp, spider
/+  io=strandio
=,  strand-fail=strand-fail:strand:spider
^-  tool:mcp
:*  'opa-get-drilling'
    'Get the latest drilling data. Optionally filter by region.'
    %-  my
    :~  ['region' [%string 'Region name (optional, e.g. us, europe, middle-east)']]
    ==
    ~
::
    ^-  thread-builder:tool:mcp
    |=  args=(map name:parameter:tool:mcp argument:tool:mcp)
    =/  m  (strand:spider ,vase)
    ^-  form:m
    =/  reg-arg=(unit argument:tool:mcp)  (~(get by args) 'region')
    ::  GET /v1/drilling/latest[?region={region}]
    ::
    =/  url=tape
      ?~  reg-arg  "https://api.oilpriceapi.com/v1/drilling/latest"
      ?>  ?=([%string @t] u.reg-arg)
      (weld "https://api.oilpriceapi.com/v1/drilling/latest?region=" (trip p.u.reg-arg))
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
