Imports System.Data
Imports System.Diagnostics
Imports System.IO
Imports MySqlConnector

Namespace AcademicSystem

    <System.ComponentModel.DesignerCategory("Form")>
    Partial Public Class BackupForm
        Inherits Form

        Private WithEvents _scheduleTimer As Timer
        Private _nextRun As DateTime

        Public Sub New()
            InitializeComponent()

            Dim designTime As Boolean = (System.ComponentModel.LicenseManager.UsageMode =
                                         System.ComponentModel.LicenseUsageMode.Designtime)
            If designTime Then Return

            If Session.RoleId <> 1 Then
                Throw New UnauthorizedAccessException("Admin role is required to run backups.")
            End If

            Text = "Backup Utility - " & Session.Username
            AddHandler btnBackupNow.Click, AddressOf BtnBackupNow_Click
            AddHandler btnRefresh.Click, Sub(sender As Object, e As EventArgs) RefreshHistory()
            AddHandler btnClose.Click, Sub(sender As Object, e As EventArgs) Close()
            AddHandler chkAutoSchedule.CheckedChanged, Sub(sender As Object, e As EventArgs) ComputeNextRun()
            AddHandler nudInterval.ValueChanged, Sub(sender As Object, e As EventArgs) ComputeNextRun()

            _scheduleTimer = New Timer() With {.Interval = 60000}
            _scheduleTimer.Start()

            SessionUi.AddStatusBar(Me)
            ComputeNextRun()
            RefreshHistory()
        End Sub

        Private Sub ComputeNextRun()
            _nextRun = DateTime.Now.AddMinutes(Convert.ToDouble(nudInterval.Value))
            lblNextRun.Text = If(chkAutoSchedule.Checked,
                                 "Next auto backup: " & _nextRun.ToString("HH:mm"),
                                 "Auto schedule is off")
        End Sub

        Private Sub ScheduleTimer_Tick(sender As Object, e As EventArgs) Handles _scheduleTimer.Tick
            If Not chkAutoSchedule.Checked Then Return
            If DateTime.Now < _nextRun Then Return
            RunBackup("AUTO")
        End Sub

        Private Sub BtnBackupNow_Click(sender As Object, e As EventArgs)
            RunBackup("MANUAL")
        End Sub

        Private Sub RunBackup(backupType As String)
            lblStatus.ForeColor = Color.SeaGreen
            lblStatus.Text = "Backup running... please wait."
            Application.DoEvents()

            Dim folder As String = Path.Combine(Application.StartupPath, "App_Data", "backups")
            Directory.CreateDirectory(folder)
            Dim fileName As String = "DB_Timon_" & DateTime.Now.ToString("yyyyMMdd_HHmmss") & ".sql"
            Dim fullPath As String = Path.Combine(folder, fileName)

            Dim startInfo As New ProcessStartInfo()
            startInfo.FileName = "C:\xampp\mysql\bin\mysqldump.exe"
            startInfo.Arguments = "-u dbt_admin -p""" & SecureConfig.GetPassword("Admin") &
                                  """ --single-transaction --result-file=""" & fullPath &
                                  """ DB_Timon"
            startInfo.UseShellExecute = False
            startInfo.CreateNoWindow = True
            startInfo.RedirectStandardError = True

            Dim exitCode As Integer
            Dim errorText As String = ""
            Try
                Using proc As Process = Process.Start(startInfo)
                    errorText = proc.StandardError.ReadToEnd()
                    proc.WaitForExit()
                    exitCode = proc.ExitCode
                End Using
            Catch ex As Exception
                exitCode = -1
                errorText = ex.Message
            End Try

            Dim status As String = If(exitCode = 0, "SUCCESS", "FAILED")
            Dim rowCount As Integer = Convert.ToInt32(
                Db.FetchTable("SELECT COUNT(*) AS total FROM grades", Nothing, "Admin").Rows(0)("total"))
            RecordBackup(fileName, backupType, rowCount, status, Session.Username, errorText)

            RefreshHistory()
            ComputeNextRun()

            If status = "SUCCESS" Then
                lblStatus.ForeColor = Color.SeaGreen
                lblStatus.Text = backupType & " backup completed: " & fullPath
            Else
                lblStatus.ForeColor = Color.Firebrick
                lblStatus.Text = "Backup failed: " & errorText
            End If
        End Sub

        Private Sub RecordBackup(fileName As String, backupType As String, rowCount As Integer,
                                 status As String, initiatedBy As String, notes As String)
            Using connection = Db.GetConnection("Admin")
                Using command As New MySqlCommand("sp_RecordBackup", connection)
                    command.CommandType = CommandType.StoredProcedure
                    command.CommandTimeout = 30
                    command.Parameters.AddWithValue("@p_file_name", fileName)
                    command.Parameters.AddWithValue("@p_backup_type", backupType)
                    command.Parameters.AddWithValue("@p_rows", rowCount)
                    command.Parameters.AddWithValue("@p_status", status)
                    command.Parameters.AddWithValue("@p_initiated_by", initiatedBy)
                    command.Parameters.AddWithValue("@p_notes", If(String.IsNullOrWhiteSpace(notes), "", notes))
                    Dim outParam As New MySqlParameter("@p_backup_id", MySqlDbType.Int64)
                    outParam.Direction = ParameterDirection.Output
                    command.Parameters.Add(outParam)

                    connection.Open()
                    command.ExecuteNonQuery()
                End Using
            End Using
        End Sub

        Private Sub RefreshHistory()
            Try
                dgvHistory.DataSource = Db.FetchTable(
                    "SELECT backup_id AS 'ID', backup_time AS 'Time', backup_type AS 'Type', " &
                    "file_name AS 'File', status AS 'Status', rows_backed_up AS 'Rows', " &
                    "initiated_by AS 'Started By', notes AS 'Notes' " &
                    "FROM backup_history ORDER BY backup_id DESC",
                    Nothing, "Admin")
            Catch ex As Exception
                lblStatus.ForeColor = Color.Firebrick
                lblStatus.Text = "Could not load backup history: " & ex.Message
            End Try
        End Sub

    End Class

End Namespace
