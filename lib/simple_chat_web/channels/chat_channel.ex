defmodule SimpleChatWeb.ChatChannel do
  use Phoenix.Channel

  alias SimpleChat.ChatServer

  def join("chat:lobby", _message, socket) do
    case ChatServer.join(socket.assigns[:user_id]) do
      {:ok, user} ->
        socket = assign(socket, :user_id, user.id)
        {:ok, messages} = ChatServer.get_messages()
        {:ok, users} = ChatServer.get_users()

        # Enviar mensagem de boas-vindas para todos
        Phoenix.PubSub.broadcast(
          SimpleChat.PubSub,
          "chat:lobby",
          {:user_joined, user}
        )

        {:ok, %{messages: messages, users: users, current_user: user}, socket}
      _ ->
        {:error, %{reason: "falha ao entrar"}}
    end
  end

  def terminate(_reason, socket) do
    user_id = socket.assigns[:user_id]
    if user_id do
      :ok = ChatServer.leave(user_id)

      # Notificar outros usuários que este usuário saiu
      Phoenix.PubSub.broadcast(
        SimpleChat.PubSub,
        "chat:lobby",
        {:user_left, user_id}
      )
    end
    :ok
  end

  def handle_in("new_message", %{"content" => content}, socket) do
    user_id = socket.assigns[:user_id]
    case ChatServer.send_message(user_id, content) do
      {:ok, _message} -> {:noreply, socket}
      _ -> {:reply, {:error, %{reason: "falha ao enviar mensagem"}}, socket}
    end
  end
end
