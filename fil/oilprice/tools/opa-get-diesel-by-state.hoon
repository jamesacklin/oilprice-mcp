::  opa-get-diesel-by-state: fetch retail diesel price for a US state
::
/-  mcp, spider
/+  io=strandio
=,  strand-fail=strand-fail:strand:spider
^-  tool:mcp
:*  'opa-get-diesel-by-state'
    'Get retail diesel price for a US state. Accepts state name or two-letter abbreviation.'
    %-  my
    :~  ['state' [%string 'US state name or abbreviation (e.g. Texas, TX, california, CA)']]
    ==
    ~['state']
::
    ^-  thread-builder:tool:mcp
    |=  args=(map name:parameter:tool:mcp argument:tool:mcp)
    =/  m  (strand:spider ,vase)
    ^-  form:m
    =/  st-arg=(unit argument:tool:mcp)  (~(get by args) 'state')
    ?~  st-arg  (strand-fail %missing-state ~)
    ?>  ?=([%string @t] u.st-arg)
    =/  states=(map tape tape)
      %-  my:nl
      :~  ["alabama" "AL"]  ["alaska" "AK"]  ["arizona" "AZ"]
          ["arkansas" "AR"]  ["california" "CA"]  ["colorado" "CO"]
          ["connecticut" "CT"]  ["delaware" "DE"]  ["florida" "FL"]
          ["georgia" "GA"]  ["hawaii" "HI"]  ["idaho" "ID"]
          ["illinois" "IL"]  ["indiana" "IN"]  ["iowa" "IA"]
          ["kansas" "KS"]  ["kentucky" "KY"]  ["louisiana" "LA"]
          ["maine" "ME"]  ["maryland" "MD"]  ["massachusetts" "MA"]
          ["michigan" "MI"]  ["minnesota" "MN"]  ["mississippi" "MS"]
          ["missouri" "MO"]  ["montana" "MT"]  ["nebraska" "NE"]
          ["nevada" "NV"]  ["new hampshire" "NH"]  ["new jersey" "NJ"]
          ["new mexico" "NM"]  ["new york" "NY"]  ["north carolina" "NC"]
          ["north dakota" "ND"]  ["ohio" "OH"]  ["oklahoma" "OK"]
          ["oregon" "OR"]  ["pennsylvania" "PA"]  ["rhode island" "RI"]
          ["south carolina" "SC"]  ["south dakota" "SD"]  ["tennessee" "TN"]
          ["texas" "TX"]  ["utah" "UT"]  ["vermont" "VT"]
          ["virginia" "VA"]  ["washington" "WA"]  ["west virginia" "WV"]
          ["wisconsin" "WI"]  ["wyoming" "WY"]
          ["district of columbia" "DC"]
      ==
    =/  input=tape  (cass (trip p.u.st-arg))
    =/  abbr=tape
      =/  hit=(unit tape)  (~(get by states) input)
      ?^  hit  u.hit
      (cuss input)
    ::  GET /v1/prices/latest?by_code=DIESEL_RETAIL_STATE_{abbr}_USD
    ::
    =/  url=tape  :(weld "https://api.oilpriceapi.com/v1/prices/latest?by_code=DIESEL_RETAIL_STATE_" abbr "_USD")
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
