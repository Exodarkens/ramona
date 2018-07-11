defmodule Ramona.Commands.Moderation do
  @moduledoc false
  use Alchemy.Cogs
  alias Alchemy.Client
  alias Ramona.{Profile, Utils}
  require Logger
  require Alchemy.Embed, as: Embed

  Cogs.def help do
    commands = Cogs.all_commands()
    |> Map.keys()
    |> Enum.join("\n")

    %Embed{color: Profile.color(), description: commands}
    |> Embed.title("All available commands")
    |> Embed.send()
  end

  @doc """
  Information about the bot.
  """
  Cogs.def info do
    {:ok, app_version} = :application.get_key(:ramona, :vsn)
    {:ok, lib_version} = :application.get_key(:alchemy, :vsn)
    {:ok, guilds} = Client.get_current_guilds()

    memories = :erlang.memory()
    {{_, io_input}, {_, io_output}} = :erlang.statistics(:io)

    mem_format = fn
      mem, :kb -> "#{div(mem, 1000)} KB"
      mem, :mb -> "#{div(mem, 1_000_000)} MB"
    end

    infos = [
      {"Prefix", Application.get_env(:ramona, :prefix)},
      {"Version", "#{app_version}"},
      {"Elixir Version", System.version()},
      {"Library", "[Alchemy #{lib_version}](https://github.com/cronokirby/alchemy)"},
      {"Owner", "[appositum#1888](https://github.com/appositum)"},
      {"Guilds", "#{length(guilds)}"},
      {"Processes", "#{length(:erlang.processes())}"},
      {"Process Memory", mem_format.(memories[:processes], :mb)},
      {"Memory Usage", mem_format.(memories[:total], :mb)},
      {"Code Memory", mem_format.(memories[:code], :mb)},
      {"ETS Memory", mem_format.(memories[:ets], :kb)},
      {"Atom Memory", mem_format.(memories[:atom], :kb)},
      {"IO Input", mem_format.(io_input, :mb)},
      {"IO Output", mem_format.(io_output, :mb)}
    ]

    Enum.reduce(infos, %Embed{color: Profile.color()}, fn {n, v}, embed ->
      Embed.field(embed, n, v, inline: true)
    end)
    |> Embed.title("Ramona")
    |> Embed.thumbnail("https://i.imgur.com/B8BmGhu.png")
    |> Embed.url("https://github.com/appositum/ramona")
    |> Embed.footer(text: "Uptime: #{Utils.uptime()}")
    |> Embed.send()
  end

  Cogs.def change_profile do
    :ok = Profile.update_file()
    {:ok, response} = Client.send_message(message.channel_id, "Processing...")

    case Client.edit_profile(avatar: Profile.avatar()) do
      {:ok, user} ->
        {:ok, guild_id} = Cogs.guild_id()
        {:ok, roles} = Client.get_roles(guild_id)

        dot_roles = Enum.filter(roles, & &1.name == ".")
        for r <- dot_roles do
          {:ok, nil} = Client.delete_role(guild_id, r.id)
        end

        {:ok, new_role} = Client.create_role(guild_id, name: ".", color: Profile.color())
        {:ok, nil} = Client.add_role(guild_id, user.id, new_role.id)

        Client.edit_message(response, "Profile successfully changed!")

      {:error, reason} ->
        Logger.error("Could not change client's profile: #{inspect(reason)}")
        [msg] = reason
        |> Poison.decode!()
        |> Map.get("avatar")

        Client.edit_message(response, ":exclamation: **#{msg}**")
    end
  end

  Cogs.set_parser(:wrapcode, &List.wrap/1)
  Cogs.def wrapcode(_) do
    wrap = ~s{Digite:\n\\`\\`\\`python\nprint('~/python/one-liners.py'.split('.')[-1])\n\\`\\`\\`\nPara enviar:\n```python\nprint('~/python/one-liners.py'.split('.')[-1])\n```\n\nOu:\n\\`\\`\\`html\n<ul style=\"list-style:none;\"><li>Cappucino</li></ul>\n\\`\\`\\`\nPara enviar:\n```html\n<ul style=\"list-style:none;\"><li>Cappucino</li></ul>\n```\nNão confunda crase (\\`) com aspas simples (')!}

    Cogs.say(wrap)
  end

  # TODO
  # Cogs.def kick(user) do
  #   {:ok, guild} = Cogs.guild()
  #   user_id = Regex.replace(~r{<|@|>}, user, "")

  #   Client.kick_member(guild.id, user_id)
  #   Client.delete_message(message)
  # end

  # TODO
  # Cogs.def ban(user, days \\ 0) do
  #   {:ok, guild} = Cogs.guild()
  #   user_id = Regex.replace(~r{<|@|>}, user, "")

  #   Client.ban_member(guild.id, user_id, days)
  #   Client.delete_message(message)
  # end

  # Cogs.def prune(quantity \\ "") do
  #   case Integer.parse(quantity) do
  #     {n, _} ->
  #       {:ok, msgs} = Client.get_messages(message.channel_id, limit: n+1)

  #       case Client.delete_messages(message.channel_id, msgs) do
  #         {:ok, nil} -> nil
  #         {:error, json} ->
  #           map = Poison.decode!(json)
  #           Logger.error ~s/Error code #{map["code"]}: #{map["message"]}/
  #       end

  #     :error ->
  #       Cogs.say(":exclamation: **You need to specify a number of messages to delete!**")
  #   end
  # end
end
