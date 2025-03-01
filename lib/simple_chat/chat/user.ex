defmodule SimpleChat.Chat.User do
  defstruct [:id, :nickname]

  @names ["Lobo", "Águia", "Leopardo", "Tigre", "Urso", "Gato", "Leão", "Raposa", "Coelho", "Coruja"]
  @adjectives ["Rápido", "Esperto", "Forte", "Veloz", "Astuto", "Sagaz", "Feroz", "Gentil", "Sábio", "Alegre"]

  def new do
    name = Enum.random(@names)
    adjective = Enum.random(@adjectives)
    nickname = "#{adjective}#{name}#{:rand.uniform(100)}"

    %__MODULE__{
      id: UUID.uuid4(),
      nickname: nickname
    }
  end
end
