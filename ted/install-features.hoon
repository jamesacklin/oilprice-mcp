::  install-features: build and install MCP tool files on agent init
::
/-  mcp, spider
/+  io=strandio, pf=pretty-file
=,  strand-fail=strand-fail:strand:spider
^-  thread:spider
|=  arg=vase
=/  =(list beam)  !<((list beam) arg)
^-  shed:khan
=/  m  (strand:spider ,vase)
^-  form:m
;<  =bowl:rand  bind:m  get-bowl:io
|-
::  base case: all files processed
::
?~  list
  (pure:m !>(~))
=*  bem  i.list
::  skip foreign-ship files
::
?.  =(p.bem our.bowl)
  ~&  >>>  %cant-install-foreign-tools
  ~&  >>>  (en-beam bem)
  $(list t.list)
::  attempt to build the file into a vase
::
;<  vux=(unit vase)  bind:m
  (build-file:io bem)
?~  vux
  ~&  >>>  [%failed-to-build (en-beam bem)]
  $(list t.list)
::  determine the poke mark from the file path
::
=/  =mark
  ?+  s.bem  %noun
    [%fil %oilprice %tools *]      %add-tool
    [%fil %oilprice %prompts *]    %add-prompt
    [%fil %oilprice %resources *]  %add-resource
  ==
::  poke the agent and continue to next file
::
~&  >  [%built (en-beam bem)]
;<  ~  bind:m
  (poke-our:io %oilprice mark u.vux)
$(list t.list)
