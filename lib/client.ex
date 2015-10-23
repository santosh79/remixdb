defmodule Remixdb.Client do
  def start(socket) do
    spawn Remixdb.Client, :loop, [socket]
  end

  def loop(socket) do
    socket |>
    store_sock_info |>
    print_new_connection |>
    serve(Remixdb.Parser.start %Remixdb.Socket{socket: socket}, self())
  end


  defp print_new_connection(socket) do
    IO.puts "new connection from"
    print_sock_info
    socket
  end

  defp print_connection_closed() do
    IO.puts "client closed connection"
    print_sock_info
  end

  defp get_key_pid(key) do
    ("remixdb_string|" <> key) |> String.to_atom |> Process.whereis
  end

  defp get_or_create_key_pid(key) do
    key_atom = ("remixdb_string|" <> key) |> String.to_atom
    key_pid = case Process.whereis(key_atom) do
      nil -> Remixdb.String.start key
      pid -> pid
    end
  end

  defp wait_for_ok(key_pid) do
    receive do
      {:ok, ^key_pid} -> :void
    end
  end

  defp wait_for_val(key_pid) do
    receive do
      {:ok, ^key_pid, val} -> val
    end
  end

  defp serve(socket, parser) do
    import Remixdb.ResponseHandler, only: [send_ok: 1, send_nil: 1, send_val: 2]
    case get_parser_response(parser) do
      {:set, args} ->
        [key, val] = args
        key_pid = get_or_create_key_pid key
        send key_pid, {self(), {:set, args}}
        wait_for_ok key_pid
        socket |> send_ok |> serve(parser)
      {:get, args} ->
        IO.puts "got GET command: "
        IO.inspect args
        [key] = args
        case get_key_pid(key) do
          nil ->
            socket |> send_nil
          key_pid ->
            send key_pid, {self(), :get}
            val = wait_for_val(key_pid)
            socket |> send_val(val)
        end
        socket |> serve(parser)
    end
  end

  defp get_parser_response(parser) do
    receive do
      {parser, args} -> args
    end
  end

  defp store_sock_info(socket) do
    peer_info = :inet.peername socket
    case peer_info do
      {:ok, {host_ip, port}} ->
        IO.inspect host_ip
        Process.put :remote_host, host_ip
        Process.put :remote_port, port
      {_} -> :void
    end
    socket
  end

  defp print_sock_info() do
    remote_host = Process.get :remote_host
    remote_port = Process.get :remote_port
    IO.puts "remote host: "
    IO.inspect remote_host
    IO.puts "and remote port: #{remote_port}"
  end
end

