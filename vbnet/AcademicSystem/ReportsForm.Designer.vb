Namespace AcademicSystem

    Partial Public Class ReportsForm

        Friend header As Label
        Friend pnlTop As Panel
        Friend lblReportType As Label
        Friend WithEvents cboReportType As ComboBox
        Friend lblSearch As Label
        Friend WithEvents txtSearch As TextBox
        Friend WithEvents btnGenerate As Button
        Friend WithEvents btnExport As Button
        Friend WithEvents btnLogout As Button
        Friend WithEvents dgvReport As DataGridView
        Friend lblStatus As Label

        Friend Sub InitializeComponent()
            Me.header = New Label()
            Me.pnlTop = New Panel()
            Me.lblReportType = New Label()
            Me.cboReportType = New ComboBox()
            Me.lblSearch = New Label()
            Me.txtSearch = New TextBox()
            Me.btnGenerate = New Button()
            Me.btnExport = New Button()
            Me.btnLogout = New Button()
            Me.dgvReport = New DataGridView()
            Me.lblStatus = New Label()
            Me.SuspendLayout()
            '
            ' header
            '
            Me.header.Dock = DockStyle.Top
            Me.header.Font = New Font("Segoe UI", 11.0F, FontStyle.Bold)
            Me.header.Height = 52
            Me.header.Padding = New Padding(14)
            Me.header.Text = "Advanced Reports - Transcript and Course Analytics"
            '
            ' pnlTop
            '
            Me.pnlTop.Dock = DockStyle.Top
            Me.pnlTop.Height = 100
            Me.lblReportType.Location = New Point(20, 20)
            Me.lblReportType.Size = New Size(110, 25)
            Me.lblReportType.Text = "Report:"
            Me.cboReportType.Location = New Point(130, 16)
            Me.cboReportType.Size = New Size(240, 28)
            Me.cboReportType.DropDownStyle = ComboBoxStyle.DropDownList
            Me.lblSearch.Location = New Point(390, 20)
            Me.lblSearch.Size = New Size(60, 25)
            Me.lblSearch.Text = "Find:"
            Me.txtSearch.Location = New Point(450, 16)
            Me.txtSearch.Size = New Size(260, 28)
            Me.btnGenerate.Location = New Point(20, 58)
            Me.btnGenerate.Size = New Size(180, 32)
            Me.btnGenerate.Text = "Generate Report"
            Me.btnExport.Location = New Point(215, 58)
            Me.btnExport.Size = New Size(150, 32)
            Me.btnExport.Text = "Export CSV"
            Me.btnLogout.Location = New Point(830, 58)
            Me.btnLogout.Size = New Size(120, 32)
            Me.btnLogout.Text = "Close"
            Me.pnlTop.Controls.Add(Me.lblReportType)
            Me.pnlTop.Controls.Add(Me.cboReportType)
            Me.pnlTop.Controls.Add(Me.lblSearch)
            Me.pnlTop.Controls.Add(Me.txtSearch)
            Me.pnlTop.Controls.Add(Me.btnGenerate)
            Me.pnlTop.Controls.Add(Me.btnExport)
            Me.pnlTop.Controls.Add(Me.btnLogout)
            '
            ' dgvReport
            '
            Me.dgvReport.AllowUserToAddRows = False
            Me.dgvReport.AutoSizeColumnsMode = DataGridViewAutoSizeColumnsMode.Fill
            Me.dgvReport.Dock = DockStyle.Fill
            Me.dgvReport.ReadOnly = True
            Me.dgvReport.SelectionMode = DataGridViewSelectionMode.FullRowSelect
            '
            ' lblStatus
            '
            Me.lblStatus.Dock = DockStyle.Bottom
            Me.lblStatus.Height = 30
            Me.lblStatus.Padding = New Padding(14, 5, 0, 0)
            Me.lblStatus.ForeColor = Color.SeaGreen
            '
            ' ReportsForm
            '
            Me.ClientSize = New Size(970, 640)
            Me.Controls.Add(Me.dgvReport)
            Me.Controls.Add(Me.pnlTop)
            Me.Controls.Add(Me.header)
            Me.Controls.Add(Me.lblStatus)
            Me.Name = "ReportsForm"
            Me.StartPosition = FormStartPosition.CenterScreen
            Me.Text = "Advanced Reports"
            Me.ResumeLayout(False)
            Me.PerformLayout()
        End Sub

    End Class

End Namespace
