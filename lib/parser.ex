defmodule Remixdb.Parser do
  def start(stream, client) do
    spawn Remixdb.Parser, :loop, [stream, client]
  end

  def loop(stream, client) do
    case read_new_command(stream) do
      {:error, _reason} -> :void
      {:set, args} ->
        send client, {self(), {:set, args}}
        loop stream, client
      {:get, args} ->
        send client, {self(), {:get, args}}
        loop stream, client
      {:exists, args} ->
        send client, {self(), {:exists, args}}
        loop stream, client
    end
  end

  defp read_new_command(stream) do
    case read_number_args(stream) do
      {:error, _reason} -> {:error, _reason}
      {:ok, num_args} ->
        IO.puts "read_number_args"
        IO.inspect num_args
        case read_args(stream, num_args) do
          {:error, _reason} -> {:error, _reason}
          {:ok, [cmd|args]} ->
            case (cmd |> String.upcase) do
              "SET"    -> {:set, args}
              "GET"    -> {:get, args}
              "EXISTS" -> {:exists, args}
              cmd ->
                IO.puts "Parser: unknown command: "
                IO.inspect cmd
            end
        end
    end
  end

  defp read_args(stream, num) do
    read_args stream, num, []
  end
  defp read_args(_stream, 0, accum) do
    {:ok, accum}
  end

  defp read_args(stream, num, accum) do
    case read_bytes(stream) do
      {:ok, num_bytes} ->
        IO.puts "reading bytes: #{num_bytes}"
        case read_data(stream, num_bytes) do
          {:ok, data} ->
            msg = data |> String.replace(~r/(.+)\r\n$/, "\\1")
            read_args stream, (num - 1), (accum ++ [msg])
        end
    end
  end

  defp read_data(stream, num_bytes) do
    val = Remixdb.StreamReader.read_line stream
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

  defp read_bytes(stream) do
    val = Remixdb.StreamReader.read_line stream
    case val do
      {:ok, data} ->
        {num_bytes, ""} = data |> String.replace(~r/\$(\d+)\r\n/, "\\1") |> Integer.parse
        {:ok, num_bytes}
    end
  end

  @doc """
  This reads a line of format "*3\r\n". And returns 3. Here 3 is any number.
  """
  def read_number_args(stream) do
    val = Remixdb.StreamReader.read_line stream
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

