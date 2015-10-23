defmodule Remixdb.Parser do
  def start(socket, client) do
    spawn Remixdb.Parser, :loop, [socket, client]
  end

  def loop(socket, client) do
    case read_new_command(socket) do
      {:error, _reason} -> :void
      {:set, args} ->
        send client, {self(), {:set, args}}
        loop socket, client
      {:get, args} ->
        send client, {self(), {:get, args}}
        loop socket, client
    end
  end

  defp read_new_command(socket) do
    case read_number_args(socket) do
      {:error, _reason} -> {:error, _reason}
      {:ok, num_args} ->
        IO.puts "read_number_args"
        IO.inspect num_args
        case read_args(socket, num_args) do
          {:error, _reason} -> {:error, _reason}
          {:ok, [cmd|args]} ->
            case (cmd |> String.upcase) do
              "SET" -> {:set, args}
              "GET" -> {:get, args}
              cmd ->
                IO.puts "Parser: unknown command: "
                IO.inspect cmd
            end
        end
    end
  end

  defp read_args(socket, num) do
    read_args socket, num, []
  end
  defp read_args(_socket, 0, accum) do
    {:ok, accum}
  end

  defp read_args(socket, num, accum) do
    case read_bytes(socket) do
      {:ok, num_bytes} ->
        IO.puts "reading bytes: #{num_bytes}"
        case read_data(socket, num_bytes) do
          {:ok, data} ->
            msg = data |> String.replace(~r/(.+)\r\n$/, "\\1")
            read_args socket, (num - 1), (accum ++ [msg])
        end
    end
  end

  defp read_data(socket, num_bytes) do
    val = :gen_tcp.recv(socket, 0)
    case val do
      {:ok, data} ->
        msg = data |> String.replace(~r/(.+)\r\n/, "\\1")
        case String.length(msg) do
          ^num_bytes ->
            IO.puts "num_bytes: #{num_bytes} and msg: #{msg}"
            {:ok, msg}
          _ -> {:error, msg}
        end
    end
  end

  defp read_bytes(socket) do
    val = :gen_tcp.recv(socket, 0)
    case val do
      {:ok, data} ->
        {num_bytes, ""} = data |> String.replace(~r/\$(\d+)\r\n/, "\\1") |> Integer.parse
        {:ok, num_bytes}
    end
  end

  @doc """
  This reads a line of format "*3\r\n". And returns 3. Here 3 is any number.
  """
  def read_number_args(socket) do
    val = :gen_tcp.recv(socket, 0)
    case val do
      {:ok, data} ->
        {num_args, ""} = data |>
          String.replace(~r/\*(\d+)\r\n/,"\\1") |> Integer.parse
        {:ok, num_args}
      {:error, reason} ->
        IO.puts "error with connection: #{reason}"
        {:error, reason}
    end
  end
end

