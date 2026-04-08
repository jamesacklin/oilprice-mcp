::  opa-set-api-key: save OilpriceAPI key to desk for authenticated requests
::
/-  mcp, spider
/+  io=strandio
=,  strand-fail=strand-fail:strand:spider
^-  tool:mcp
:*  'opa-set-api-key'
    'Set your OilpriceAPI key. Get a free key at https://www.oilpriceapi.com (200 requests/month).'
    %-  my
    :~  ['api_key' [%string 'Your OilpriceAPI key']]
    ==
    ~['api_key']
::
    ^-  thread-builder:tool:mcp
    |=  args=(map name:parameter:tool:mcp argument:tool:mcp)
    =/  m  (strand:spider ,vase)
    ^-  form:m
    =/  key-arg=(unit argument:tool:mcp)  (~(get by args) 'api_key')
    ?~  key-arg  (strand-fail %missing-api-key ~)
    ?>  ?=([%string @t] u.key-arg)
    =/  key=@t  p.u.key-arg
    ::  H1: encode as hex literal to avoid corruption from special chars
    ::
    =/  hoon-src=@t
      %-  crip
      ;:  welp
        "^-(cord "
        (scow %ux `@ux`key)
        ")"
      ==
    ;<  =bowl:rand  bind:m  get-bowl:io
    ::  write key as a hoon literal to /lib/oilprice-key/hoon
    ::
    ;<  ~  bind:m
      %:  send-raw-card:io
          %pass   /set-api-key
          %arvo   %c  %info
          [q.byk.bowl %& [/lib/oilprice-key/hoon %ins %hoon !>(hoon-src)]~]
      ==
    %-  pure:m
    !>  ^-  json
    %-  pairs:enjs:format
    :~  ['type' s+'text']
        ['text' s+'API key saved. All opa-* tools are now ready.']
    ==
==
