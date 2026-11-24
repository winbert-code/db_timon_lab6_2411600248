Imports System.Data

Namespace AcademicSystem

    <System.ComponentModel.DesignerCategory("Form")>
    Partial Public Class AuditLogForm
        Inherits Form

        Private _auditTable As DataTable

        Public Sub New()
            InitializeComponent()

            Dim designTime As Boolean = (System.ComponentModel.LicenseManager.UsageMode =
                                         System.ComponentModel.LicenseUsageMode.Designtime)
            If designTime Then Return

            If Session.RoleId <> 1 Then
                Throw New UnauthorizedAccessException("Admin role is required to view the audit trail.")
            End If

            Text = "Audit Trail Viewer - " & Session.Username
            AddHandler btnApply.Click, AddressOf BtnApply_Click
            AddHandler btnExportPdf.Click, AddressOf BtnExportPdf_Click
            AddHandler btnClose.Click, Sub(sender As Object, e As EventArgs) Close()
            AddHandler dgvAudit.SelectionChanged, AddressOf DgvAudit_SelectionChanged

            dtpFrom.Value = DateTime.Today.AddDays(-30)
            dtpTo.Value = DateTime.Today.AddDays(1)
            LoadFilterValues()
            SessionUi.AddStatusBar(Me)
            ApplyFilter()
        End Sub

        Private Sub LoadFilterValues()
            cboUser.Items.Clear()
            cboUser.Items.Add("(All users)")
            For Each row As DataRow In Db.FetchTable(
                "SELECT DISTINCT app_user FROM audit_log WHERE app_user IS NOT NULL ORDER BY app_user",
                Nothing, "Admin").Rows
                cboUser.Items.Add(Convert.ToString(row("app_user")))
            Next
            cboUser.SelectedIndex = 0

            cboTable.Items.Clear()
            cboTable.Items.Add("(All tables)")
            For Each row As DataRow In Db.FetchTable(
                "SELECT DISTINCT table_name FROM audit_log ORDER BY table_name",
                Nothing, "Admin").Rows
                cboTable.Items.Add(Convert.ToString(row("table_name")))
            Next
            cboTable.SelectedIndex = 0

            cboAction.Items.Clear()
            cboAction.Items.Add("(All actions)")
            For Each row As DataRow In Db.FetchTable(
                "SELECT DISTINCT action_type FROM audit_log ORDER BY action_type",
                Nothing, "Admin").Rows
                cboAction.Items.Add(Convert.ToString(row("action_type")))
            Next
            cboAction.SelectedIndex = 0
        End Sub

        Private Sub ApplyFilter()
            Dim sql As String =
                "SELECT audit_id AS 'ID', event_time AS 'Time', db_user AS 'DB User', " &
                "app_user AS 'App User', table_name AS 'Table', action_type AS 'Action', " &
                "record_id AS 'Record', old_values AS 'Before', new_values AS 'After', " &
                "host_name AS 'Host' FROM audit_log " &
                "WHERE event_time >= @from AND event_time < @to"
            Dim parameters As New Dictionary(Of String, Object) From {
                {"@from", dtpFrom.Value.Date},
                {"@to", dtpTo.Value.Date.AddDays(1)}
            }

            If cboUser.SelectedIndex > 0 Then
                sql &= " AND app_user = @appUser"
                parameters.Add("@appUser", Convert.ToString(cboUser.SelectedItem))
            End If
            If cboTable.SelectedIndex > 0 Then
                sql &= " AND table_name = @tableName"
                parameters.Add("@tableName", Convert.ToString(cboTable.SelectedItem))
            End If
            If cboAction.SelectedIndex > 0 Then
                sql &= " AND action_type = @actionType"
                parameters.Add("@actionType", Convert.ToString(cboAction.SelectedItem))
            End If
            sql &= " ORDER BY event_time DESC, audit_id DESC"

            Try
                _auditTable = Db.FetchTable(sql, parameters, "Admin")
                dgvAudit.DataSource = _auditTable
                lblStatus.ForeColor = Color.SeaGreen
                lblStatus.Text = _auditTable.Rows.Count & " audit record(s) found."
            Catch ex As Exception
                lblStatus.ForeColor = Color.Firebrick
                lblStatus.Text = "Filter failed: " & ex.Message
            End Try
        End Sub

        Private Sub BtnApply_Click(sender As Object, e As EventArgs)
            ApplyFilter()
        End Sub

        Private Sub DgvAudit_SelectionChanged(sender As Object, e As EventArgs)
            If dgvAudit.CurrentRow Is Nothing Then Return
            Dim row As DataGridViewRow = dgvAudit.CurrentRow
            If row.IsNewRow Then Return
            txtBefore.Text = ReadableValues(Convert.ToString(row.Cells("Before").Value))
            txtAfter.Text = ReadableValues(Convert.ToString(row.Cells("After").Value))
        End Sub

        Private Function ReadableValues(value As String) As String
            If String.IsNullOrWhiteSpace(value) Then Return "(none)"
            Dim quote As String = ChrW(34).ToString()
            Dim text As String = value.Replace("{" & quote, "").Replace(quote & "}", "")
            text = text.Replace(quote, "").Replace(",", vbLf).Replace(":", " = ")
            Return text
        End Function

        Private Sub BtnExportPdf_Click(sender As Object, e As EventArgs)
            If _auditTable Is Nothing OrElse _auditTable.Rows.Count = 0 Then
                lblStatus.ForeColor = Color.Firebrick
                lblStatus.Text = "No audit records to export."
                Return
            End If

            Using dialog As New SaveFileDialog()
                dialog.Filter = "PDF files (*.pdf)|*.pdf"
                dialog.FileName = "audit_trail_" & DateTime.Now.ToString("yyyyMMdd_HHmm") & ".pdf"
                If dialog.ShowDialog() <> DialogResult.OK Then Return

                Dim lines As New List(Of String)()
                For Each row As DataRow In _auditTable.Rows
                    lines.Add(String.Format("{0} | {1} | {2} | {3} | {4}",
                                            Convert.ToString(row("Time")),
                                            Convert.ToString(row("App User")),
                                            Convert.ToString(row("Table")),
                                            Convert.ToString(row("Action")),
                                            Convert.ToString(row("Record"))))
                    lines.Add("    Before: " & ReadableValues(Convert.ToString(row("Before"))).Replace(vbLf, " ; "))
                    lines.Add("    After:  " & ReadableValues(Convert.ToString(row("After"))).Replace(vbLf, " ; "))
                    lines.Add("")
                Next

                PdfExporter.Export("DB_Timon - Audit Trail (compliance report)", lines, dialog.FileName)
                lblStatus.ForeColor = Color.SeaGreen
                lblStatus.Text = "Audit trail exported: " & dialog.FileName
            End Using
        End Sub

    End Class

End Namespace
