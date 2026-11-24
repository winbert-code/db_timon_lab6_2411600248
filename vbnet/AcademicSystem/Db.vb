Imports System.Data
Imports MySqlConnector

Namespace AcademicSystem

    ' Central database access using the dedicated Lab 6 role accounts.
    ' Credentials are read from the encrypted SecureConfig store; pooling
    ' and explicit timeouts are configured on every connection.
    Friend Module Db

        Private _roleName As String = "Admin"

        Friend Sub UseRole(role As String)
            Select Case If(role, "").Trim().ToLowerInvariant()
                Case "admin"
                    _roleName = "Admin"
                Case "teacher"
                    _roleName = "Teacher"
                Case "student"
                    _roleName = "Student"
                Case Else
                    _roleName = "Admin"
            End Select
        End Sub

        Friend ReadOnly Property CurrentRole As String
            Get
                Return _roleName
            End Get
        End Property

        Private Function DbUserFor(role As String) As String
            Select Case role
                Case "Teacher"
                    Return "dbt_teacher"
                Case "Student"
                    Return "dbt_student"
                Case Else
                    Return "dbt_admin"
            End Select
        End Function

        Friend Function BuildConnectionString(role As String) As String
            Dim builder As New MySqlConnectionStringBuilder()
            builder.Server = "localhost"
            builder.Port = 3306
            builder.Database = "DB_Timon"
            builder.UserID = DbUserFor(role)
            builder.Password = SecureConfig.GetPassword(role)
            builder.CharacterSet = "utf8mb4"
            builder.AllowUserVariables = True
            builder.Pooling = True
            builder.MinimumPoolSize = 1
            builder.MaximumPoolSize = 20
            builder.ConnectionTimeout = 15UI
            builder.DefaultCommandTimeout = 30UI
            Return builder.ConnectionString
        End Function

        Friend Function GetConnection(Optional role As String = Nothing) As MySqlConnection
            Return New MySqlConnection(BuildConnectionString(If(role, _roleName)))
        End Function

        ' Opens a connection and passes the application user to audit triggers
        ' through the @app_user session variable.
        Private Function OpenConnection(Optional role As String = Nothing) As MySqlConnection
            Dim connection As MySqlConnection = GetConnection(role)
            Try
                connection.Open()
                Using setAppUser As New MySqlCommand("SET @app_user = @appUser", connection)
                    Dim appUser As String = If(String.IsNullOrWhiteSpace(Session.Username),
                                               "system", Session.Username)
                    setAppUser.Parameters.AddWithValue("@appUser", appUser)
                    setAppUser.ExecuteNonQuery()
                End Using
                Return connection
            Catch
                connection.Dispose()
                Throw
            End Try
        End Function

        Friend Function FetchTable(sql As String,
                                   Optional parameters As Dictionary(Of String, Object) = Nothing,
                                   Optional role As String = Nothing) As DataTable
            Dim table As New DataTable()

            Using connection = OpenConnection(role)
                Using command As New MySqlCommand(sql, connection)
                    command.CommandTimeout = 30
                    AddParameters(command, parameters)
                    Using reader = command.ExecuteReader()
                        table.Load(reader)
                    End Using
                End Using
            End Using

            Return table
        End Function

        Friend Function Execute(sql As String,
                                Optional parameters As Dictionary(Of String, Object) = Nothing,
                                Optional role As String = Nothing) As Integer
            Using connection = OpenConnection(role)
                Using command As New MySqlCommand(sql, connection)
                    command.CommandTimeout = 30
                    AddParameters(command, parameters)
                    Return command.ExecuteNonQuery()
                End Using
            End Using
        End Function

        Friend Sub AddParameters(command As MySqlCommand,
                                 parameters As Dictionary(Of String, Object))
            If parameters Is Nothing Then Return

            For Each item In parameters
                Dim value As Object = item.Value
                If value Is Nothing Then value = DBNull.Value
                command.Parameters.AddWithValue(item.Key, value)
            Next
        End Sub

    End Module

End Namespace
