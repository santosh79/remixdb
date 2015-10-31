defmodule Remixdb.Client do
  def start(socket) do
    spawn Remixdb.Client, :loop, [socket]
  end

  def loop(socket) do
    socket |>
    store_sock_info |>
    print_new_connection |>
    setup_socket
  end

  def setup_socket(socket) do
    stream = %Remixdb.Socket{socket: socket}
    parser_name = get_parser_name()
    Remixdb.SimpleServer.start parser_name, Remixdb.Parser, [stream]
    serve socket
  end

  defp get_parser_name do
    "remix_db_parser_for|" <> (self() |> :erlang.pid_to_list |> List.to_string) |> String.to_atom
  end

  defp print_new_connection(socket) do
    IO.puts "new connection from"
    print_sock_info
    socket
  end

  defp serve(socket) do
    import Remixdb.ResponseHandler, only: [send_ok: 1, send_nil: 1, send_val: 2, send_response: 2]
    case get_parser_response() do
      :flushall ->
        response = Remixdb.KeyHandler.flushall
        socket |> send_response(response)
      :dbsize ->
        val = Remixdb.KeyHandler.dbsize()
        socket |> send_response(val)
      {:exists, [key]} ->
        case Remixdb.KeyHandler.exists?(key) do
          false ->
            socket |> send_response(0)
          true ->
            socket |> send_response(1)
        end
      {:set, [key, val]} ->
        response = Remixdb.KeyHandler.set key, val
        socket |> send_response(response)
      {:get, [key]} ->
        case Remixdb.KeyHandler.get(key) do
          nil ->
            socket |> send_nil
          val ->
            socket |> send_val(val)
        end
    end
    socket |> serve
  end

  defp get_parser_response do
    get_parser_name() |> Remixdb.Parser.read
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

