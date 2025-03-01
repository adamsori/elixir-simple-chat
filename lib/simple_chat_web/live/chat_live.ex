defmodule SimpleChatWeb.ChatLive do
  use SimpleChatWeb, :live_view

  alias SimpleChat.ChatServer
  alias SimpleChat.Chat.User

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      Phoenix.PubSub.subscribe(SimpleChat.PubSub, "chat:lobby")

      {:ok, user} = ChatServer.join()
      {:ok, messages} = ChatServer.get_messages()
      {:ok, users} = ChatServer.get_users()

      socket = socket
        |> assign(:current_user, user)
        |> assign(:messages, messages)
        |> assign(:users, users)
        |> assign(:new_message, "")

      {:ok, socket}
    else
      # Inicializar todos os assigns necessários mesmo durante o carregamento inicial
      {:ok, socket
        |> assign(:loading, true)
        |> assign(:current_user, %{nickname: "Carregando..."}) # Valor temporário
        |> assign(:messages, [])
        |> assign(:users, [])
        |> assign(:new_message, "")
      }
    end
  end

  @impl true
  def handle_event("send_message", %{"message" => content}, socket) do
    if String.trim(content) != "" do
      {:ok, _message} = ChatServer.send_message(socket.assigns.current_user.id, content)
    end

    {:noreply, assign(socket, :new_message, "")}
  end

  @impl true
  def handle_info({:new_message, message}, socket) do
    updated_messages = [message | socket.assigns.messages] |> Enum.take(50)
    {:noreply, assign(socket, :messages, updated_messages)}
  end

  @impl true
  def handle_info({:user_joined, user}, socket) do
    # Se não é o usuário atual
    if user.id != socket.assigns.current_user.id do
      updated_users = [user | socket.assigns.users]
      {:noreply, assign(socket, :users, updated_users)}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_info({:user_left, user_id}, socket) do
    updated_users = Enum.filter(socket.assigns.users, &(&1.id != user_id))
    {:noreply, assign(socket, :users, updated_users)}
  end
  # TODO: Implementar o handle_info para os eventos de mensagens e usuários
  @impl true
  def render(assigns) do
    ~L"""
    <div class="container mx-auto p-4">
      <h1 class="text-2xl font-bold mb-4">Chat em Tempo Real - Phoenix LiveView</h1>

      <div class="grid grid-cols-4 gap-4">
        <div class="col-span-3">
          <div class="bg-white shadow-md rounded-lg p-4">
            <div class="mb-4">
              <p class="text-gray-700">
                Você está conectado como <span class="font-bold"><b><%= @current_user.nickname %></b></span>
              </p>
            </div>

            <div id="chat-messages" class="h-96 overflow-y-auto mb-4 p-2 border rounded-lg">
              <%= for message <- @messages do %>
                <div class="message <%= if message.user_id == @current_user.id, do: "text-right" %>">
                  <p>
                    <b><%= message.nickname %></b>
                    <span class="text-gray-500 text-xs">
                      <%= message.timestamp |> Calendar.strftime("%H:%M:%S") %>
                    </span>
                  </p>
                  <p class="<%= if message.user_id == @current_user.id, do: "bg-blue-100", else: "bg-gray-100" %> inline-block p-2 rounded-lg">
                    <%= message.content %>
                  </p>
                </div>
              <% end %>
            </div>

            <form phx-submit="send_message">
              <div class="flex">
                <input type="text" name="message" value="<%= @new_message %>"
                       placeholder="Digite sua mensagem..."
                       class="flex-grow p-2 border rounded-l-lg focus:outline-none"
                       autocomplete="off"/>
                <button type="submit" class="bg-blue-500 text-white p-2 rounded-r-lg">Enviar</button>
              </div>
            </form>
          </div>
        </div>

        <div class="col-span-1">
          <div class="bg-white shadow-md rounded-lg p-4">
            <h2 class="text-lg font-bold mb-2">Usuários Online (<%= length(@users) %>)</h2>
            <ul>
              <%= for user <- @users do %>
                <li class="<%= if user.id == @current_user.id, do: "font-bold" %>">
                  <%= user.nickname %>
                </li>
              <% end %>
            </ul>
          </div>
        </div>
      </div>
    </div>
    """
  end
end
