::  opa-get-futures: fetch latest futures price for a contract
::
/-  mcp, spider
/+  io=strandio
=,  strand-fail=strand-fail:strand:spider
^-  tool:mcp
:*  'opa-get-futures'
    'Get the latest futures price for a contract. Use BZ for Brent or CL for WTI.'
    %-  my
    :~  ['contract' [%string 'Futures contract code: BZ (Brent) or CL (WTI)']]
    ==
    ~['contract']
::
    ^-  thread-builder:tool:mcp
    |=  args=(map name:parameter:tool:mcp argument:tool:mcp)
    =/  m  (strand:spider ,vase)
    ^-  form:m
    =/  con-arg=(unit argument:tool:mcp)  (~(get by args) 'contract')
    ?~  con-arg  (strand-fail %missing-contract ~)
    ?>  ?=([%string @t] u.con-arg)
    =/  contract=tape  (cuss (trip p.u.con-arg))
    ::  GET /v1/futures/latest?contract={contract}
    ::
    =/  url=tape  (weld "https://api.oilpriceapi.com/v1/futures/latest?contract=" contract)
    ::  load API key
    ::
    ;<  =bowl:rand  bind:m  get-bowl:io
    ;<  vax=(unit vase)  bind:m
      (build-file:io [our.bowl q.byk.bowl da+now.bowl] /lib/oilprice-key)
    ?~  vax  (strand-fail %no-api-key ~)
    =/  api-key=@t  !<(@t u.vax)
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
