Namespace AcademicSystem

    ' Explicit application-level audit entries (login, logout, timeouts).
    ' Grade INSERT/UPDATE/DELETE entries are written automatically by the
    ' database triggers in 10_Lab6_Security_Audit_Backup.sql.
    Friend Module AuditLogger

        Friend Sub Log(action As String, tableName As String, recordId As String,
                       oldValues As String, newValues As String)
            Dim parameters As New Dictionary(Of String, Object) From {
                {"@app", If(String.IsNullOrWhiteSpace(Session.Username), "system", Session.Username)},
                {"@table", tableName},
                {"@action", action},
                {"@rid", If(recordId, "")},
                {"@old", If(oldValues, "")},
                {"@new", If(newValues, "")}
            }

            Db.Execute(
                "INSERT INTO audit_log " &
                "(db_user, app_user, table_name, action_type, record_id, old_values, new_values, host_name) " &
                "VALUES (USER(), @app, @table, @action, @rid, @old, @new, @@hostname)",
                parameters, "Admin")
        End Sub

    End Module

End Namespace
