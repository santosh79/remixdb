defmodule Remixdb.SimpleServer do

  def start(server_name, module_name) do
    start server_name, module_name, []
  end
  def start(server_name, module_name, args) when is_list(args)  do
    spawn(fn ->
      loop server_name, module_name, (apply(module_name, :init, args))
    end) |>
    Process.register(server_name)
  end

  def loop(server_name, module_name, state) do
    receive do
      {from, request} ->
        case(apply(module_name, :handle, [request, state])) do
          {response, new_state} ->
            send from, {server_name, response}
            loop server_name, module_name, new_state
        end
    end
  end

  def rpc(server_name, request) do
    send server_name, {self(), request}
    receive do
      {^server_name, response} -> response
    end
  end

end

