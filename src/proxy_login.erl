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

