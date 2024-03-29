%%%-------------------------------------------------------------------
%%% @author User
%%% @copyright (C) 2019, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 28. Июнь 2019 0:54
%%%-------------------------------------------------------------------
-module(bobc_net).
-author("User").

%% API
-export([tcp_listener_loop/2, safe_send/3]).

%% Local functions
-export([accept/2]).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Function that starts tcp_listener %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
tcp_listener_loop(Port, [ModuleName | [FunctionName | Args]]) ->
  {ok, ListenSocket} = gen_tcp:listen(Port, [binary, {active, false}, {packet, raw}]),
  spawn(?MODULE, accept, [ListenSocket, [ModuleName | [FunctionName | Args]]]),
  timer:sleep(infinity),
  ok.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Function that accepts new connections and send %%
%% them to ModuleName:FunctionName                %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
accept(ListenSocket, [ModuleName | [FunctionName | Args]]) ->
  {ok, Socket} = gen_tcp:accept(ListenSocket),
  spawn(ModuleName, FunctionName, [[Socket] ++ Args]),
  accept(ListenSocket, [ModuleName | [FunctionName | Args]]).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Sends the term to the {Host, Port}           %%
%% If it is impossible to establish connection  %%
%% Calls the ModuleName:FunctionName(Arguments) %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
safe_send({Host, Port}, Term, {ModuleName, FunctionName, Arguments}) ->
  case gen_tcp:connect(Host, Port, [binary, {active, true}, {packet, raw}]) of
    {ok, Socket} ->
      gen_tcp:send(Socket, term_to_binary(Term)),
      gen_tcp:close(Socket);
    {error, _} -> spawn_link(ModuleName, FunctionName, Arguments)
  end.