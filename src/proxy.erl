%% -*- mode: nitrogen -*-
-module (proxy).
-compile(export_all).
-include_lib("nitrogen/include/wf.hrl").
-include("records.hrl").
-include("proxy_text.hrl").

main() -> #template { file="./site/templates/bare.html" }.

title() -> "3proxy".

body() ->
  wf:comet(fun() -> ?MODULE:proc() end, <<"proc">>),
  Usr = wf:user(),
  case Usr of
    'undefined' ->
      wf:wire(logu, #hide { effect = slide, speed = 1 });
    _ ->
      wf:wire(login, #hide { effect = slide, speed = 1 })
  end,
  [
   #h1 { id = pr3, text = "3proxy" },
   #flash {},
   #button { id = login, text = ?USR_LOGIN, postback = login },
   #panel { id = logu, body = [
      ?FWEL, "&nbsp;", wf:user(), "&nbsp;", #button { id = logout, text = ?FLOGU, postback = logout }
     ] },
   #panel { id = filter, body = [
      ?FFILT, "&nbsp",
      #link { id = ldb, text = ?FDB, postback = { show, fdb, ldb } },
      "&nbsp;",
      #link { id = ltime, text = ?FTIME, postback = { show, ftime, ltime } },
      "&nbsp;",
      #link { id = lusr, text = ?FUSR, postback = { show, fusr, lusr } },
      "&nbsp;",
      #link { id = lhost, text = ?FHOST, postback = { show, fhost, lhost } },
      "&nbsp;",
      #link { id = lurl, text = ?FURL, postback = { show, furl, lurl } },
      "&nbsp;",
      #link { id = ltraf, text = ?FTRAF, postback = { show, ftraf, ltraf } }
     ]
   },
   #panel { id = fdb, class = fp, actions = #hide { effect = slide, speed = 2 }, body = [
      ?FDB, "&nbsp;", #dropdown { id = fdb_el, options = [ #option { text = "", value = "" } ] },
      "&nbsp;", ?FV, "&nbsp;", #dropdown { id = fv_el, options = [ #option { text = "", value = "" } ] }
     ]
   },
   #panel { id = ftime, class = fp, actions = #hide { effect = slide, speed = 2 }, body = [
      ?FDAY, "&nbsp;", 
      ?FST, "&nbsp", #textbox { id = fday_st },
      ?FEND, "&nbsp", #textbox { id = fday_end },
      #br {}, ?FTIME, "&nbsp;",
      ?FST, "&nbsp;", #textbox { id = ftime_st },
      ?FEND, "&nbsp;", #textbox { id = ftime_end }
     ]
   },
   #panel { id = fusr, class = fp, actions = #hide { effect = slide, speed = 2 }, body = [
      #link { text = ?FUSR, postback = { reload, "users", fusr_el } }, "&nbsp",
      #dropdown { id = fusr_el, options = [ #option { text = "", value = "" } ] }, "&nbsp;"
     ]
   },
   #panel { id = fhost, class = fp, actions = #hide { effect = slide, speed = 2 }, body = [
      #link { text = ?FHOST, postback = { reload, "hosts", fhost_el } }, "&nbsp",
      #dropdown { id = fhost_el, options = [ #option { text = "", value = "" } ] }, "&nbsp;"
     ]
   },
   #panel { id = furl, class = fp, actions = #hide { effect = slide, speed = 2 }, body = [
      ?FURL, "&nbsp", #textbox { id = furl_el }
     ]
   },
   #panel { id = ftraf, class = fp, actions = #hide { effect = slide, speed = 2 }, body = [
      ?FTRAF, "&nbsp;", 
      ?FST, "&nbsp", #textbox { id = ftraf_st },
      ?FEND, "&nbsp", #textbox { id = ftraf_end }
     ]
   },
   #button { id = bfilter, text = ?FFILT, postback = bfilter },
   #panel { id = pdata, body = [
      %#singlerow { id = pdatar, cells = [] },
      #table { id = data_tab, rows = [] },
      #br {},
      #link { id = pprev, text = ?FPREV, postback = pprev }, "&nbsp;",
      #dropdown { id = pages, options = [ #option { text = "10", value = "10" } ] }, "&nbsp;",
      #link { id = pnext, text = ?FNEXT, postback = pnext }
     ]
   }
  ].

event({ show, El, Pt }) ->
  case wf:state_default(El, false) of
    false ->
      %wf:wire(Pt, #animate { options = [{borderWidth, "1px"}] }),
      show_menu(El, Pt);
    true ->
      %wf:wire(Pt, #animate { options = [{borderWidth, "0px"}] }),
      hide_menu(El, Pt)
  end;

event({ reload, View, El }) ->
  wf:replace(El, #dropdown { id = El, options = [ #option { text = ?FW, value = "" } ] }),
  wf:send(<<"proc">>, { grp, View, El});

event({ chg, fdb_el }) ->
  %wf:wire(#alert { text = wf:q(fdb_el) }),
  wf:session(fdb_el, wf:q(fdb_el)),
  wf:replace(fv_el, #dropdown { id = fv_el, options = [ #option { text = ?FW, value = "" } ] }),
  wf:send(<<"proc">>, {upd, fv_el});

event({ chg, fv_el }) ->
  case wf:q(fv_el) of
    "user_u" ->
      %hide_menu(),
      show_menu(fusr, lusr),
      wf:state(showed, [{fusr, lusr}|wf:state_default(showed, [])]),
      wf:wire(bfilter, fusr_el, #validate { validators = [ #is_required { text = ?USR_REQ } ] });
    "user_ud" ->
      %hide_menu(),
      show_menu(fusr, lusr),
      wf:state(showed, [{fusr, lusr}|wf:state_default(showed, [])]),
      wf:wire(bfilter, fusr_el, #validate { validators = [ #is_required { text = ?USR_REQ } ] }),
      show_menu(ftime, ltime),
      wf:state(showed, [{ftime, ltime}|wf:state_default(showed, [])]),
      wf:wire(bfilter, fday_st, #validate { validators = [ #is_required { text = ?USR_REQ } ] }),
      wf:wire(bfilter, fday_end, #validate { validators = [ #is_required { text = ?USR_REQ } ] }),
      wf:wire(bfilter, ftime_st, #validate { validators = [ #is_required { text = ?USR_REQ } ] }),
      wf:wire(bfilter, ftime_end, #validate { validators = [ #is_required { text = ?USR_REQ } ] });
    _ ->
      ok
  end;

event(bfilter) ->
  Tid = wf:temp_id(),
  wf:flash(Tid, "Wait..."),
  Url = case wf:q(fv_el) of
          "user_u" ->
            lists:flatten(io_lib:format("http://~s:~s@~s/~s/_design/norm/_view/user_u?key=[\"~s\"]&limit=~s&skip=~B",
              [wf:user(), wf:session_default(<<"upass">>, "1"), ?HOST, wf:q(fdb_el), wf:q(fusr_el), wf:q(pages),
              wf:state_default(<<"page">>, 0)]));
          _ ->
            wf:flash("Not valid view"),
            ""
        end,
  wf:flush(),
  gen_data(Url),
  %wf:flash("Done"),
  wf:wire(Tid, #hide { effect = slide, speed = 300 });
  %wf:flush();
  %wf:send(<<"proc">>, {get_dat, Url, Tid});

event(pnext) ->
  wf:state(<<"page">>, wf:state_default(<<"page">>, 0) + list_to_integer(wf:q(pages))),
  event(bfilter);

event(pprev) ->
  Pg = wf:state_default(<<"page">>, 0) - list_to_integer(wf:q(pages)),
  if
    Pg > 0 ->
      wf:state(<<"page">>, Pg);
    true ->
      wf:state(<<"page">>, 0)
  end,
  event(bfilter);

event(logout) ->
  %wf:wire(logu, #hide { effect = slide, speed = 1 }),
  wf:logout(),
  wf:redirect("/proxy");

event(login) ->
  %wf:session(fdb_el, wf:q(fdb_el)),
  wf:redirect_to_login("/proxy/login").

show_menu(El, PEl) ->
  ?MODULE:El(),
  wf:wire(PEl, #animate { options = [{backgroundColor, "yellow"}] }),
  wf:wire(El, #show { effect = slide, speed = 200, options = [ { direction, up } ] }),
  wf:state(El, true).

hide_menu(El, PEl) ->
  wf:wire(PEl, #animate { options = [{backgroundColor, "white"}] }),
  wf:wire(El, #hide { effect = slide, speed = 200, options = [ { direction, up } ] }),
  wf:state(El, false).

hide_menu() ->
  Mns = wf:state_default(showed, []),
  lists:foreach(fun({El, Pt}) -> hide_menu(El, Pt) end, Mns).

fdb() ->
  case wf:state_default({cache, fdb_el}, 0) of
    0 ->
      wf:state({cache, fdb_el}, 1),
      wf:replace(fdb_el, #dropdown { id = fdb_el, options = [ #option { text = ?FW, value = "" } ] }),
      %wf:update(fdb_el, [ #option { text = ?FW, value = "" } ]),
      wf:send(<<"proc">>, {upd, fdb_el});
    _ ->
      ok
  end.

ftime() -> ok.

fusr() ->
  %get_grp("users", fusr_el).
  case wf:state_default({cache, fusr_el}, 0) of
    0 ->
      wf:state({cache, fusr_el}, 1),
      wf:replace(fusr_el, #dropdown { id = fusr_el, options = [ #option { text = ?FW, value = "" } ] }),
      wf:send(<<"proc">>, {grp, "users", fusr_el});
    _ ->
      ok
  end.

fhost() ->
  %get_grp("hosts", fhost_el).
  case wf:state_default({cache, fhost_el}, 0) of
    0 ->
      wf:state({cache, fhost_el}, 1),
      wf:replace(fhost_el, #dropdown { id = fhost_el, options = [ #option { text = ?FW, value = "" } ] }),
      wf:send(<<"proc">>, {grp, "hosts", fhost_el});
    _ ->
      ok
  end.

furl() -> ok.

ftraf() -> ok.

gen_data(Url) ->
  {ok, {{_, Cod, HMsg}, _, Body}} = httpc:request(get, {Url, []}, [], [{body_format, binary}]),
  case Cod of
    200 ->
      {struct, Data} = mochijson2:decode(Body),
      Rows = proplists:get_value(<<"rows">>, Data, []),
      FunRow = fun({struct, Row}) ->
                 {struct, Vals} = proplists:get_value(<<"value">>, Row, {struct, []}),
                 Vals
               end,
      TabRows = lists:map(FunRow, Rows),
      [Hd|_] = TabRows,
      FunHd = fun({Key, _}) ->
                LKey = binary_to_list(Key),
                St = case LKey of
                       "host" ->
                         "width: 20%;";
                       "url" ->
                         "width: 40%;";
                       _ ->
                         "width: 10%;"
                     end,
                #tablecell { style = St, class = pdatah, text = LKey }
              end,
      wf:update(data_tab, lists:map(FunHd, Hd)),
      FunC = fun({Key, Dat}) ->
                LKey = binary_to_list(Key),
                St = case LKey of
                       "host" ->
                         "width: 20%;";
                       "url" ->
                         "width: 40%;";
                       _ ->
                         "width: 10%;"
                     end,
               #tablecell { style = St, class = pdatac, text = binary_to_list(Dat) }
             end,
      FunR = fun(Els) ->
               #tablerow { cells = lists:map(FunC, Els) }
             end,
      wf:insert_bottom(data_tab, lists:map(FunR, TabRows));
    _ ->
      wf:flash(["Couchdb error: ", HMsg])
  end.

get_grp(View, Elem) ->
  Url = lists:flatten(io_lib:format("http://~s:~s@~s/~s/_design/grp/_view/~s?group=true",
    [wf:user(), wf:session_default(<<"upass">>, "1"), ?HOST, wf:session_default(fdb_el, ""), View])),
  {ok, {{_, Cod, HMsg}, _, Body}} = httpc:request(get, {Url, []}, [], [{body_format, binary}]),
  case Cod of
    200 ->
      Opts = fun({struct, El}) ->
               Ret = proplists:get_value(<<"key">>, El, ""),
               Ell = binary_to_list(Ret),
               #option { text = Ell, value = Ell}
             end,
      {struct, [{_, Dat}]} = mochijson2:decode(Body),
      wf:replace(Elem, #dropdown { id = Elem,
        options = [#option { text = "", value = "" }|lists:map(Opts, Dat)] });
    _ ->
      %wf:flash([?FLOGIN, "&nbsp;", #button { id = login, text = ?USR_LOGIN, postback = login }])
      wf:replace(Elem, #dropdown { id = Elem, value = "", options = [ #option { text = "", value = "" } ] }),
      wf:flash(["Couchdb error: ", HMsg])
  end.

proc() ->
  receive
    {upd, fdb_el} ->
      Url = lists:flatten(io_lib:format("http://~s/_all_dbs", [?HOST])),
      {ok, {{_, 200, _}, _, Body}} = httpc:request(get, {Url, []}, [], [{body_format, binary}]),
      %wf:wire(#alert { text = Body }),
      Opts = fun(El) ->
               Ell = binary_to_list(El),
               #option { text = Ell, value = Ell }
             end,
      wf:replace(fdb_el, #dropdown { id = fdb_el,
        options = [#option { text = "", value = "" }|lists:map(Opts, mochijson2:decode(Body))], postback = { chg, fdb_el } });
      %wf:update(fdb_el, [ #option { text = "", value = "" } | lists:map(Opts, mochijson2:decode(Body)) ]);
      %wf:flush(),
      %proc();
    {upd, fv_el} ->
      Url = lists:flatten(io_lib:format("http://~s:~s@~s/~s/_design/norm", [wf:user(), wf:session_default(<<"upass">>, "1"), ?HOST, wf:session_default(fdb_el, "")])),
      {ok, {{_, Cod, HMsg}, _, Body}} = httpc:request(get, {Url, []}, [], [{body_format, binary}]),
      %wf:wire(#alert { text = Body }),
      case Cod of
        200 ->
          Opts = fun({El, _}) ->
                   Ell = binary_to_list(El),
                   #option { text = Ell, value = Ell }
                 end,
          {struct, MVws} = mochijson2:decode(Body),
          %wf:wire(#alert { text = MVws }),
          {struct, Vws} = proplists:get_value(<<"views">>, MVws, {struct, []}),
          wf:replace(fv_el, #dropdown { id = fv_el,
            options = [#option { text = "", value = "" }|lists:map(Opts, Vws)], postback = { chg, fv_el } });
        _ ->
          wf:replace(fv_el, #dropdown { id = fv_el, value = "", options = [ #option { text = "", value = "" } ] }),
          wf:flash(["Couchdb error: ", HMsg])
      end;
      %wf:flush(),
      %proc()
    {grp, View, El} ->
      get_grp(View, El);
    {get_dat, Url, Tid} ->
      wf:wire(#alert { text = Url }),
      gen_data(Url),
      wf:flash("Done"),
      wf:wire(Tid, #hide { effect = slide, speed = 300 })
  end,
  wf:flush(),
  proc().
