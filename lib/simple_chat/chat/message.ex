defmodule SimpleChat.Chat.Message do
  defstruct [:id, :user_id, :nickname, :content, :timestamp]

  def new(user_id, nickname, content) do
    %__MODULE__{
      id: UUID.uuid4(),
      user_id: user_id,
      nickname: nickname,
      content: content,
      timestamp: DateTime.utc_now()
    }
  end
end
