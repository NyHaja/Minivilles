using Godot;
using BCrypt.Net;

public partial class AuthBridge : Node
{
	// Utilisation : Inscription
	public string PreparePasswordForDB(string passwordFromClient)
	{
		return BCrypt.Net.BCrypt.HashPassword(passwordFromClient);
	}

	// Utilisation : Authentification
	public bool VerifyLogin(string passwordInput, string storedHashFromDB)
	{
		return BCrypt.Net.BCrypt.Verify(passwordInput, storedHashFromDB);
	}
}
