Namespace AcademicSystem

    Partial Public Class BackupForm

        Friend lblHeader As Label
        Friend WithEvents btnBackupNow As Button
        Friend WithEvents btnRefresh As Button
        Friend WithEvents chkAutoSchedule As CheckBox
        Friend lblInterval As Label
        Friend WithEvents nudInterval As NumericUpDown
        Friend lblNextRun As Label
        Friend WithEvents dgvHistory As DataGridView
        Friend lblStatus As Label
        Friend WithEvents btnClose As Button

        Friend Sub InitializeComponent()
            Me.lblHeader = New Label()
            Me.btnBackupNow = New Button()
            Me.btnRefresh = New Button()
            Me.chkAutoSchedule = New CheckBox()
            Me.lblInterval = New Label()
            Me.nudInterval = New NumericUpDown()
            Me.lblNextRun = New Label()
            Me.dgvHistory = New DataGridView()
            Me.lblStatus = New Label()
            Me.btnClose = New Button()
            Me.SuspendLayout()

            '
            ' header / controls
            '
            Me.lblHeader.Font = New Font("Segoe UI", 12.0F, FontStyle.Bold)
            Me.lblHeader.Location = New Point(30, 16)
            Me.lblHeader.Size = New Size(940, 26)
            Me.lblHeader.Text = "Backup Utility - manual backup, history and simulated automatic schedule"

            Me.btnBackupNow.Location = New Point(30, 55)
            Me.btnBackupNow.Size = New Size(200, 38)
            Me.btnBackupNow.Text = "Backup Now"

            Me.btnRefresh.Location = New Point(245, 55)
            Me.btnRefresh.Size = New Size(110, 38)
            Me.btnRefresh.Text = "Refresh History"

            Me.chkAutoSchedule.Location = New Point(375, 63)
            Me.chkAutoSchedule.Size = New Size(175, 24)
            Me.chkAutoSchedule.Text = "Enable auto schedule"

            Me.lblInterval.Location = New Point(565, 63)
            Me.lblInterval.Size = New Size(100, 24)
            Me.lblInterval.Text = "Interval (min):"

            Me.nudInterval.Location = New Point(665, 58)
            Me.nudInterval.Size = New Size(80, 28)
            Me.nudInterval.Minimum = 1
            Me.nudInterval.Maximum = 1440
            Me.nudInterval.Value = 5

            Me.lblNextRun.Location = New Point(765, 63)
            Me.lblNextRun.Size = New Size(215, 24)
            Me.lblNextRun.ForeColor = Color.SeaGreen

            Me.dgvHistory.Location = New Point(30, 105)
            Me.dgvHistory.Size = New Size(940, 330)
            Me.dgvHistory.ReadOnly = True
            Me.dgvHistory.AllowUserToAddRows = False
            Me.dgvHistory.SelectionMode = DataGridViewSelectionMode.FullRowSelect
            Me.dgvHistory.AutoSizeColumnsMode = DataGridViewAutoSizeColumnsMode.Fill
            Me.dgvHistory.Anchor = AnchorStyles.Top Or AnchorStyles.Left Or AnchorStyles.Right

            Me.lblStatus.Location = New Point(30, 450)
            Me.lblStatus.Size = New Size(940, 40)
            Me.lblStatus.ForeColor = Color.SeaGreen

            Me.btnClose.Location = New Point(30, 500)
            Me.btnClose.Size = New Size(100, 36)
            Me.btnClose.Text = "Close"

            '
            ' BackupForm
            '
            Me.ClientSize = New Size(1000, 550)
            Me.StartPosition = FormStartPosition.CenterScreen
            Me.Text = "Backup Utility"
            Me.Controls.Add(Me.lblHeader)
            Me.Controls.Add(Me.btnBackupNow)
            Me.Controls.Add(Me.btnRefresh)
            Me.Controls.Add(Me.chkAutoSchedule)
            Me.Controls.Add(Me.lblInterval)
            Me.Controls.Add(Me.nudInterval)
            Me.Controls.Add(Me.lblNextRun)
            Me.Controls.Add(Me.dgvHistory)
            Me.Controls.Add(Me.lblStatus)
            Me.Controls.Add(Me.btnClose)
            Me.ResumeLayout(False)
            Me.PerformLayout()
        End Sub

    End Class

End Namespace
