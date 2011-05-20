%% @author Oleg Krivosheev <amranello@gmail.com>
%% @copyright 2010 Oleg Krivosheev

%% Copyright 2010 Oleg Krivosheev
%%
%% Licensed under the Apache License, Version 2.0 (the "License");
%% you may not use this file except in compliance with the License.
%% You may obtain a copy of the License at
%%
%% http://www.apache.org/licenses/LICENSE-2.0
%%
%% Unless required by applicable law or agreed to in writing, software
%% distributed under the License is distributed on an "AS IS" BASIS,
%% WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
%% See the License for the specific language governing permissions and
%% limitations under the License.

%% -*- mode: nitrogen -*-
-module (proxy_login).
-compile(export_all).
-include_lib("nitrogen/include/wf.hrl").
-include("records.hrl").
-include("proxy_text.hrl").

main() -> #template { file="./site/templates/bare.html" }.

title() -> "3Proxy login".

body() ->
  wf:wire(ulogin, uname, #validate { validators = [ #is_required { text = ?USR_REQ } ] }),
  wf:wire(ulogin, upass, #validate { validators = [ #is_required { text = ?USR_REQ },
    #custom { text = ?USR_NPASS, function = fun(_, Val) -> ?MODULE:check_user(Val) end } ] }),
  [
   #h1 { style = "margin: 10px", text = "Login page" },
   #panel {
     style = "margin: 20px",
     body = [
       #label { text = ?USR_NAME },
       #textbox { id = uname, next = upass },
       #label { text = ?USR_PASS },
       #password { id = upass, next = ulogin },
       #br {},
       #button { id = ulogin, text = ?USR_LOGIN, postback = ulogin }
     ]
   }
  ].

event(ulogin) ->
  wf:user(wf:q(uname)),
  wf:role(<<"view">>, true),
  wf:session(<<"upass">>, wf:q(upass)),
  wf:redirect_from_login("/proxy").

check_user(Pass) ->
  Url = lists:flatten(io_lib:format("http://~s:~s@~s/~s", [wf:q(uname), Pass, ?HOST, wf:session_default(fdb_el, "")])),
  {ok, {{_, Cod, _}, _, _}} = httpc:request(get, {Url, []}, [], [{body_format, binary}]),
  case Cod of
    200 ->
      true;
    _ ->
      false
  end.

