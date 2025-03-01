defmodule SimpleChat.ChatServer do
  use GenServer

  alias SimpleChat.Chat.{Room, User, Message}

  @default_room "lobby"

  # API pública
  def start_link(_) do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  def join(user_id \\ nil) do
    GenServer.call(__MODULE__, {:join, user_id})
  end

  def leave(user_id) do
    GenServer.call(__MODULE__, {:leave, user_id})
  end

  def send_message(user_id, content) do
    GenServer.call(__MODULE__, {:send_message, user_id, content})
  end

  def get_messages do
    GenServer.call(__MODULE__, :get_messages)
  end

  def get_users do
    GenServer.call(__MODULE__, :get_users)
  end

  # Implementação do GenServer
  @impl true
  def init(_) do
    # Iniciar com uma sala de chat padrão
    {:ok, %{rooms: %{@default_room => Room.new(@default_room)}}}
  end

  @impl true
  def handle_call({:join, nil}, _from, state) do
    user = User.new()
    updated_room = state.rooms[@default_room] |> Room.add_user(user)
    updated_rooms = Map.put(state.rooms, @default_room, updated_room)

    {:reply, {:ok, user}, %{state | rooms: updated_rooms}}
  end

  @impl true
  def handle_call({:join, user_id}, _from, state) do
    case find_user(state, user_id) do
      nil ->
        # Se não encontrar o usuário, criamos um novo
        handle_call({:join, nil}, _from, state)
      user ->
        {:reply, {:ok, user}, state}
    end
  end

  @impl true
  def handle_call({:leave, user_id}, _from, state) do
    updated_room = state.rooms[@default_room] |> Room.remove_user(user_id)
    updated_rooms = Map.put(state.rooms, @default_room, updated_room)

    {:reply, :ok, %{state | rooms: updated_rooms}}
  end

  @impl true
  def handle_call({:send_message, user_id, content}, _from, state) do
    case find_user(state, user_id) do
      nil ->
        {:reply, {:error, :user_not_found}, state}
      user ->
        message = Message.new(user.id, user.nickname, content)
        room = state.rooms[@default_room]
        updated_room = Room.add_message(room, message)
        updated_rooms = Map.put(state.rooms, @default_room, updated_room)

        # Notificar todos os clientes sobre a nova mensagem
        Phoenix.PubSub.broadcast(
          SimpleChat.PubSub,
          "chat:#{@default_room}",
          {:new_message, message}
        )

        {:reply, {:ok, message}, %{state | rooms: updated_rooms}}
    end
  end

  @impl true
  def handle_call(:get_messages, _from, state) do
    messages = state.rooms[@default_room] |> Room.get_messages()
    {:reply, {:ok, messages}, state}
  end

  @impl true
  def handle_call(:get_users, _from, state) do
    users = state.rooms[@default_room] |> Room.get_users()
    {:reply, {:ok, users}, state}
  end

  # Funções privadas auxiliares
  defp find_user(state, user_id) do
    room = state.rooms[@default_room]
    Map.get(room.users, user_id)
  end
end
