Imports System.Security.Cryptography

Namespace AcademicSystem

    ' PBKDF2-HMAC-SHA256 with a unique random salt per password.
    ' Stored format: pbkdf2_sha256$<iterations>$<base64 salt>$<base64 hash>
    ' This is the same format used by the seed accounts in 03_Lab3_Users_Roles_Auth.sql.
    Friend Module PasswordHasher

        Private Const Iterations As Integer = 100000
        Private Const SaltSize As Integer = 16
        Private Const KeySize As Integer = 32
        Private Const AlgorithmTag As String = "pbkdf2_sha256"

        Friend Function HashPassword(password As String) As String
            Dim salt(SaltSize - 1) As Byte
            Using rng = RandomNumberGenerator.Create()
                rng.GetBytes(salt)
            End Using

            Dim key As Byte() = Derive(password, salt, Iterations)
            Return AlgorithmTag & "$" & Iterations.ToString() & "$" &
                   Convert.ToBase64String(salt) & "$" & Convert.ToBase64String(key)
        End Function

        Friend Function VerifyPassword(password As String, storedValue As String) As Boolean
            If String.IsNullOrWhiteSpace(storedValue) Then Return False

            Dim parts As String() = storedValue.Split("$"c)
            If parts.Length <> 4 OrElse parts(0) <> AlgorithmTag Then Return False

            Dim iterations As Integer
            If Not Integer.TryParse(parts(1), iterations) OrElse iterations <= 0 Then Return False

            Try
                Dim salt As Byte() = Convert.FromBase64String(parts(2))
                Dim expected As Byte() = Convert.FromBase64String(parts(3))
                Dim actual As Byte() = Derive(password, salt, iterations)
                Return CryptographicOperations.FixedTimeEquals(expected, actual)
            Catch
                Return False
            End Try
        End Function

        Private Function Derive(password As String, salt As Byte(), iterations As Integer) As Byte()
            Return Rfc2898DeriveBytes.Pbkdf2(password, salt, iterations,
                                             HashAlgorithmName.SHA256, KeySize)
        End Function

    End Module

End Namespace
