defmodule SimpleChat.Chat.Room do
  defstruct [:id, :name, messages: [], users: %{}]

  def new(name) do
    %__MODULE__{
      id: UUID.uuid4(),
      name: name
    }
  end

  def add_user(room, user) do
    updated_users = Map.put(room.users, user.id, user)
    %{room | users: updated_users}
  end

  def remove_user(room, user_id) do
    updated_users = Map.delete(room.users, user_id)
    %{room | users: updated_users}
  end

  def add_message(room, message) do
    %{room | messages: [message | room.messages]}
  end

  def get_messages(room, limit \\ 50) do
    room.messages
    |> Enum.take(limit)
    |> Enum.reverse()
  end

  def get_users(room) do
    Map.values(room.users)
  end
end
