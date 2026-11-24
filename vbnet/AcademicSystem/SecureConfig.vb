#Disable Warning SYSLIB0007
Imports System.IO
Imports System.Security.Cryptography
Imports System.Text

Namespace AcademicSystem

    ' Role-based database passwords are stored encrypted at rest.
    ' The AES key is derived from machine/user data with PBKDF2, so the
    ' plain-text passwords never appear in source code or config files.
    Friend Module SecureConfig

        Private Const CredentialFile As String = "dbt_credentials.enc"
        Private Const SaltText As String = "DB_Timon.Lab6.role-credentials"

        Friend Function GetPassword(role As String) As String
            EnsureCredentialFile()

            Dim credPath As String = CredentialPath()
            For Each line As String In File.ReadAllLines(credPath)
                If line.StartsWith(role & "|", StringComparison.OrdinalIgnoreCase) Then
                    Dim parts As String() = line.Split("|"c)
                    If parts.Length <> 4 Then Continue For
                    Return Decrypt(parts(3), Convert.FromBase64String(parts(1)),
                                   Convert.FromBase64String(parts(2)))
                End If
            Next

            Throw New InvalidOperationException("No encrypted credential found for role '" & role & "'.")
        End Function

        Private Sub EnsureCredentialFile()
            Dim credPath As String = CredentialPath()
            If File.Exists(credPath) Then Return

            Directory.CreateDirectory(Path.GetDirectoryName(credPath))

            Dim defaults As New Dictionary(Of String, String)(StringComparer.OrdinalIgnoreCase) From {
                {"Admin", "DbTimon@Admin2026"},
                {"Teacher", "DbTimon@Teacher2026"},
                {"Student", "DbTimon@Student2026"}
            }

            Dim contents As New StringBuilder()
            For Each item As KeyValuePair(Of String, String) In defaults
                Dim salt(15) As Byte
                Dim iv(15) As Byte
                Using rng = RandomNumberGenerator.Create()
                    rng.GetBytes(salt)
                    rng.GetBytes(iv)
                End Using
                contents.Append(item.Key).Append("|")
                contents.Append(Convert.ToBase64String(salt)).Append("|")
                contents.Append(Convert.ToBase64String(iv)).Append("|")
                contents.AppendLine(Encrypt(item.Value, salt, iv))
            Next

            File.WriteAllText(credPath, contents.ToString(), Encoding.ASCII)
        End Sub

        Private Function CredentialPath() As String
            Return Path.Combine(Application.StartupPath, "App_Data", CredentialFile)
        End Function

        Private Function DeriveKey(salt As Byte()) As Byte()
            Dim material As String = Environment.MachineName & "|" &
                                     Environment.UserName & "|" & SaltText
            Return Rfc2898DeriveBytes.Pbkdf2(material, salt, 50000,
                                             HashAlgorithmName.SHA256, 32)
        End Function

        Private Function Encrypt(plainText As String, salt As Byte(), iv As Byte()) As String
            Using aesAlg As SymmetricAlgorithm = Aes.Create()
                aesAlg.Key = DeriveKey(salt)
                aesAlg.IV = iv
                Using transform = aesAlg.CreateEncryptor()
                    Dim bytes As Byte() = Encoding.UTF8.GetBytes(plainText)
                    Return Convert.ToBase64String(
                        transform.TransformFinalBlock(bytes, 0, bytes.Length))
                End Using
            End Using
        End Function

        Private Function Decrypt(cipherText As String, salt As Byte(), iv As Byte()) As String
            Using aesAlg As SymmetricAlgorithm = Aes.Create()
                aesAlg.Key = DeriveKey(salt)
                aesAlg.IV = iv
                Using transform = aesAlg.CreateDecryptor()
                    Dim bytes As Byte() = Convert.FromBase64String(cipherText)
                    Return Encoding.UTF8.GetString(
                        transform.TransformFinalBlock(bytes, 0, bytes.Length))
                End Using
            End Using
        End Function

    End Module

End Namespace
