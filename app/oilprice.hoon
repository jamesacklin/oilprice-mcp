::  oilprice: MCP server for OilpriceAPI energy commodity data
::
/-  mcp
/+  dbug, verb, server, default-agent,
    jut=json-utils, ml=mcp
::
::  helpers
::
|%
++  print-tang-to-wain
  |=  =tang
  ^-  wain
  %-  zing
  %+  turn  tang
  |=  =tank
  %+  turn  (wash [0 80] tank)
  |=  =tape
  (crip tape)
::
++  simple-response
  |=  [eyre-id=@ta status=@ud headers=(list [key=@t value=@t])]
  ^-  (list card)
  %+  give-simple-payload:app:server  eyre-id
  ^-  simple-payload:http
  [[status headers] ~]
::
++  send-event
  |=  [eyre-id=@ta =json]
  ^-  (list card)
  %+  give-simple-payload:app:server  eyre-id
  ^-  simple-payload:http
  :-  [200 ~[['content-type' 'text/event-stream'] ['cache-control' 'no-cache']]]
  %-  some
  %-  as-octt:mimes:html
  ;:  welp
      "data: "
      (trip (en:json:html json))
      "\0a\0a"
  ==
::
::  state
::
+$  card  card:agent:gall
+$  versioned-state  $:  state-0  ==
+$  state-0
  $:  %0
      tools=(set tool:mcp)          ::  registered MCP tools
      prompts=(set prompt:mcp)      ::  registered MCP prompts
      resources=(set resource:mcp)  ::  registered MCP resources
  ==
--
::
::  agent
::
%-  agent:dbug
^-  agent:gall
=|  state-0
=*  state  -  ::  agent state
%+  verb  &
|_  =bowl:gall
+*  this   .
    def    ~(. (default-agent this %|) bowl)
::
++  on-agent  on-agent:def
++  on-leave  on-leave:def
++  on-fail   on-fail:def
++  on-save   !>(state)
::
++  on-load
  |=  =vase
  ^-  (quip card _this)
  =/  old  !<(versioned-state vase)
  `this(state old)
::
++  on-init
  ^-  (quip card _this)
  :_  this
  :~  :*  %pass  /eyre/connect
          %arvo  %e  %connect
          [`/mcp/oilpriceapi dap.bowl]
      ==
      :*  %pass  ~
          %arvo  %k
          %fard  q.byk.bowl
          %install-features
          :-  %noun
          !>  ^-  (list beam)
          %+  turn
            .^  (list path)
                %ct
                /(scot %p our.bowl)/[q.byk.bowl]/(scot %da now.bowl)/fil/oilprice
            ==
          |=  pax=path
          ^-  beam
          %-  need
          %-  de-beam
          %+  welp
            /(scot %p our.bowl)/[q.byk.bowl]/(scot %da now.bowl)
          pax
  ==  ==
::
++  on-poke
  |=  [=mark =vase]
  ^-  (quip card _this)
  |^
  ?+    mark  (on-poke:def mark vase)
      %handle-http-request
    (handle-req !<([@ta inbound-request:eyre] vase))
  ::
      ?(%add-tool %add-prompt %add-resource)
    ?>  =(src our):bowl
    :-  ~
    ?-  mark
      %add-tool      this(tools (~(put in tools) !<(tool:mcp vase)))
      %add-prompt    this(prompts (~(put in prompts) !<(prompt:mcp vase)))
      %add-resource  this(resources (~(put in resources) !<(resource:mcp vase)))
    ==
  ==
  ::
  ++  handle-req
    |=  [eyre-id=@ta req=inbound-request:eyre]
    ^-  (quip card _this)
    ?.  authenticated.req
      :_  this
      (send-event eyre-id (internal:error:rpc:ml 'Authentication required' ~))
    ?+    method.request.req
        [(simple-response eyre-id 405 ~) this]
    ::
        %'GET'
      :_  this
      (send-event eyre-id (pairs:enjs:format ~[['type' s+'connection']]))
    ::
        %'POST'
      =/  content-type=(unit @t)
        (get-header:http 'content-type' header-list.request.req)
      ::  M3: accept content-type with charset params (e.g. application/json; charset=utf-8)
      ::
      ?.  ?&  ?=(^ content-type)
              =(0 (fall (find "application/json" (cass (trip u.content-type))) 1))
          ==
        [(simple-response eyre-id 415 ~) this]
      =/  parsed=(unit json)  (de:json:html q:(need body.request.req))
      ?~  parsed  [(simple-response eyre-id 400 ~) this]
      %.  u.parsed
      |=  jon=json
      =/  id=(unit json)      (~(get jo:jut jon) /id)
      =/  method=(unit json)  (~(get jo:jut jon) /method)
      ?+    method
          :_  this
          (send-event eyre-id (method:error:rpc:ml 'Method not found' id))
      ::
          [~ [%s %'notifications/initialized']]
        [(simple-response eyre-id 200 ~) this]
      ::
          [~ [%s %'initialize']]
        :_  this
        %:  send-event  eyre-id
        %-  pairs:enjs:format
        %+  welp  ?~(id ~ ['id' u.id]~)
        :~  ['jsonrpc' s+'2.0']
            :-  'result'
            %-  pairs:enjs:format
            :~  ['protocolVersion' s+'2024-11-05']
                :-  'capabilities'
                %-  pairs:enjs:format
                :~  ['tools' (pairs:enjs:format ~[['listChanged' b+%.n]])]
                    ['resources' (pairs:enjs:format ~[['subscribe' b+%.n] ['listChanged' b+%.n]])]
                    ['prompts' (pairs:enjs:format ~[['listChanged' b+%.n]])]
                ==
                :-  'serverInfo'
                %-  pairs:enjs:format
                :~  ['name' s+'oilprice-api']
                    ['version' s+'1.0.0']
        ==  ==  ==  ==
      ::
          [~ [%s %'tools/list']]
        :_  this
        (send-event eyre-id (result:rpc:ml (mcp-tools-to-json:ml tools) id))
      ::
          [~ [%s %'resources/list']]
        :_  this
        (send-event eyre-id (result:rpc:ml (mcp-resources-to-json:ml resources) id))
      ::
          [~ [%s %'prompts/list']]
        :_  this
        (send-event eyre-id (result:rpc:ml (mcp-prompts-to-json:ml prompts) id))
      ::
          [~ [%s %'prompts/get']]
        =/  prompt-name=(unit @t)
          (~(deg jo:jut jon) /params/name so:dejs:format)
        ?~  prompt-name
          :_  this
          (send-event eyre-id (params:error:rpc:ml 'Missing prompt name' id))
        =/  prompt-results
          %+  murn  ~(tap in prompts)
          |=  =prompt:mcp
          ?.  =(name.prompt u.prompt-name)  ~
          `prompt
        ?~  prompt-results
          :_  this
          (send-event eyre-id (method:error:rpc:ml (crip "Prompt not found") id))
        =/  =prompt:mcp  i.prompt-results
        =/  prompt-args=(map name:argument:prompt:mcp @t)
          %-  fall
          :-  (~(deg jo:jut jon) /params/arguments (om so):dejs:format)
          *(map name:argument:prompt:mcp @t)
        :_  this
        %:  send-event  eyre-id
        %-  result:rpc:ml
        :-  %-  pairs:enjs:format
            :~  ['description' s+desc.prompt]
                ['messages' (prompt-messages-to-json:ml (messages-builder.prompt prompt-args))]
            ==
        id  ==
      ::
          [~ [%s %'tools/call']]
        ::  H3: accept both string and numeric JSON-RPC ids
        ::
        ?~  id
          :_  this
          (send-event eyre-id (params:error:rpc:ml 'Missing request ID' ~))
        :_  this
        =/  tool-name=(unit @t)
          (~(deg jo:jut jon) /params/name so:dejs:format)
        ?~  tool-name
          (send-event eyre-id (params:error:rpc:ml 'Missing tool name' id))
        =/  tool-results
          %+  murn  ~(tap in tools)
          |=  foo=tool:mcp
          ?.  =(name.foo u.tool-name)  ~
          `foo
        ?~  tool-results
          (send-event eyre-id (params:error:rpc:ml (crip "Tool not found") id))
        =/  arguments=(unit json)  (~(get jo:jut jon) /params/arguments)
        ?~  arguments
          (send-event eyre-id (params:error:rpc:ml 'Missing arguments' id))
        =/  args-map=(unit (map @t json))
          ?:  ?=([%o *] u.arguments)  `p.u.arguments
          ~
        ?~  args-map
          (send-event eyre-id (params:error:rpc:ml 'Invalid arguments' id))
        =>  |%
            ++  parse-arg
              |=  jon=json
              ^-  argument:tool:mcp
              ?+  jon  ~
                [%a *]   [%array (turn p.jon parse-arg)]
                [%b ?]   [%boolean p.jon]
                [%o *]   [%object (~(run by p.jon) parse-arg)]
                [%s @t]  [%string p.jon]
              ::  H2: gracefully handle non-integer numbers
              ::  by falling back to string if %ud parse fails
              ::
                  [%n @ta]
                =/  num=(unit @ud)  (rush p.jon dem:ag)
                ?^  num  [%number u.num]
                [%string `@t`p.jon]
              ==
            --
        ^-  (list card)
        :~  :*  %pass  /res/tool/[eyre-id]/(scot %t (en:json:html u.id))
                %arvo  %k
                %lard  q.byk.bowl
                %-  thread-builder.i.tool-results
                (~(run by u.args-map) parse-arg)
        ==  ==
      ==
    ==
  --
::
++  on-peek
  |=  =(pole knot)
  ^-  (unit (unit cage))
  ?+  pole  (on-peek:def `path`pole)
    [%x %tools ~]       ``json+!>((mcp-tools-to-json:ml tools))
    [%x %resources ~]    ``json+!>((mcp-resources-to-json:ml resources))
    [%x %prompts ~]      ``json+!>((mcp-prompts-to-json:ml prompts))
  ==
::
++  on-arvo
  |=  [=(pole knot) =sign-arvo]
  ^-  (quip card _this)
  ?+    pole  `this
  ::
      [%eyre %connect ~]
    ?>  ?=([%eyre %bound *] sign-arvo)
    ?:  accepted.sign-arvo  `this
    %-  (slog leaf/"oilprice: failed to bind to /mcp/oilpriceapi" ~)
    `this
  ::
      [%res feat=@ta eyre-id=@ta rpc-id=@ta und=*]
    ::  H3: decode JSON id from wire path (supports string and numeric ids)
    ::
    =/  parsed-id=(unit json)  (de:json:html (slav %t rpc-id.pole))
    ?+    sign-arvo  (on-arvo:def pole sign-arvo)
    ::
        [%khan %arow *]
      ?:  ?=(%.n -.p.sign-arvo)
        :_  this
        (send-event eyre-id.pole (internal:error:rpc:ml (crip (print-tang-to-wain tang.p.p.sign-arvo)) parsed-id))
      ?>  ?=([%khan %arow %.y %noun *] sign-arvo)
      =/  [%khan %arow %.y %noun =vase]  sign-arvo
      =/  result=json  !<(json vase)
      ?+    feat.pole
          :_  this
          (send-event eyre-id.pole (internal:error:rpc:ml 'Unknown response type' parsed-id))
      ::
          %tool
        =/  response-text=(unit @t)
          ?+  result  ~
            [%s *]  `p.result
          ::
              [%o *]
            =/  typ=(unit @t)  (~(deg jo:jut result) /type so:dejs:format)
            =/  txt=(unit @t)  (~(deg jo:jut result) /text so:dejs:format)
            ?~  typ  ~
            ?~  txt  ~
            ?.  =(u.typ 'text')  ~
            txt
          ==
        ?~  response-text
          :_  this
          (send-event eyre-id.pole (internal:error:rpc:ml 'Invalid tool response' parsed-id))
        :_  this
        (send-event eyre-id.pole (mcp-text-result:ml u.response-text parsed-id))
      ==
    ==
  ==
::
++  on-watch
  |=  =(pole knot)
  ^-  (quip card _this)
  ?+  pole  (on-watch:def `path`pole)
    [%http-response eyre-id=@ta ~]  `this
  ==
--
