::  opa-get-storage: fetch oil storage data for Cushing or SPR
::
/-  mcp, spider
/+  io=strandio
=,  strand-fail=strand-fail:strand:spider
^-  tool:mcp
:*  'opa-get-storage'
    'Get oil storage data. Defaults to Cushing, Oklahoma. Use spr for the Strategic Petroleum Reserve.'
    %-  my
    :~  ['facility' [%string 'Storage facility: cushing (default) or spr (Strategic Petroleum Reserve)']]
    ==
    ~
::
    ^-  thread-builder:tool:mcp
    |=  args=(map name:parameter:tool:mcp argument:tool:mcp)
    =/  m  (strand:spider ,vase)
    ^-  form:m
    =/  fac-arg=(unit argument:tool:mcp)  (~(get by args) 'facility')
    =/  facility=tape
      ?:  ?&(?=(^ fac-arg) ?=([%string @t] u.fac-arg))
        (cass (trip p.u.fac-arg))
      "cushing"
    ::  GET /v1/storage/{facility}
    ::
    =/  url=tape  (weld "https://api.oilpriceapi.com/v1/storage/" facility)
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
        ~[['Authorization' (crip (weld "Bearer " (trip api-key)))] ['Accept' 'application/json']]
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
