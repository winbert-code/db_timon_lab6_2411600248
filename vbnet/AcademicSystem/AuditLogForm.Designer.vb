Namespace AcademicSystem

    Partial Public Class AuditLogForm

        Friend lblHeader As Label
        Friend lblFrom As Label
        Friend lblTo As Label
        Friend lblUser As Label
        Friend lblTable As Label
        Friend lblAction As Label
        Friend WithEvents dtpFrom As DateTimePicker
        Friend WithEvents dtpTo As DateTimePicker
        Friend WithEvents cboUser As ComboBox
        Friend WithEvents cboTable As ComboBox
        Friend WithEvents cboAction As ComboBox
        Friend WithEvents btnApply As Button
        Friend WithEvents btnExportPdf As Button
        Friend WithEvents btnClose As Button
        Friend WithEvents dgvAudit As DataGridView
        Friend lblBefore As Label
        Friend lblAfter As Label
        Friend txtBefore As TextBox
        Friend txtAfter As TextBox
        Friend lblStatus As Label

        Friend Sub InitializeComponent()
            Me.lblHeader = New Label()
            Me.lblFrom = New Label()
            Me.lblTo = New Label()
            Me.lblUser = New Label()
            Me.lblTable = New Label()
            Me.lblAction = New Label()
            Me.dtpFrom = New DateTimePicker()
            Me.dtpTo = New DateTimePicker()
            Me.cboUser = New ComboBox()
            Me.cboTable = New ComboBox()
            Me.cboAction = New ComboBox()
            Me.btnApply = New Button()
            Me.btnExportPdf = New Button()
            Me.btnClose = New Button()
            Me.dgvAudit = New DataGridView()
            Me.lblBefore = New Label()
            Me.lblAfter = New Label()
            Me.txtBefore = New TextBox()
            Me.txtAfter = New TextBox()
            Me.lblStatus = New Label()
            Me.SuspendLayout()

            '
            ' header and filters
            '
            Me.lblHeader.Font = New Font("Segoe UI", 12.0F, FontStyle.Bold)
            Me.lblHeader.Location = New Point(30, 16)
            Me.lblHeader.Size = New Size(940, 26)
            Me.lblHeader.Text = "Audit Trail Viewer - filter by date, user, table and action"

            Me.lblFrom.Location = New Point(30, 50)
            Me.lblFrom.Size = New Size(40, 24)
            Me.lblFrom.Text = "From:"
            Me.dtpFrom.Location = New Point(70, 47)
            Me.dtpFrom.Size = New Size(140, 28)
            Me.dtpFrom.Format = DateTimePickerFormat.Short

            Me.lblTo.Location = New Point(225, 50)
            Me.lblTo.Size = New Size(30, 24)
            Me.lblTo.Text = "To:"
            Me.dtpTo.Location = New Point(255, 47)
            Me.dtpTo.Size = New Size(140, 28)
            Me.dtpTo.Format = DateTimePickerFormat.Short

            Me.lblUser.Location = New Point(415, 50)
            Me.lblUser.Size = New Size(45, 24)
            Me.lblUser.Text = "User:"
            Me.cboUser.Location = New Point(460, 47)
            Me.cboUser.Size = New Size(120, 28)
            Me.cboUser.DropDownStyle = ComboBoxStyle.DropDownList

            Me.lblTable.Location = New Point(595, 50)
            Me.lblTable.Size = New Size(45, 24)
            Me.lblTable.Text = "Table:"
            Me.cboTable.Location = New Point(640, 47)
            Me.cboTable.Size = New Size(120, 28)
            Me.cboTable.DropDownStyle = ComboBoxStyle.DropDownList

            Me.lblAction.Location = New Point(775, 50)
            Me.lblAction.Size = New Size(50, 24)
            Me.lblAction.Text = "Action:"
            Me.cboAction.Location = New Point(825, 47)
            Me.cboAction.Size = New Size(100, 28)
            Me.cboAction.DropDownStyle = ComboBoxStyle.DropDownList

            Me.btnApply.Location = New Point(935, 45)
            Me.btnApply.Size = New Size(45, 30)
            Me.btnApply.Text = "Apply"

            '
            ' audit grid
            '
            Me.dgvAudit.Location = New Point(30, 90)
            Me.dgvAudit.Size = New Size(950, 300)
            Me.dgvAudit.ReadOnly = True
            Me.dgvAudit.AllowUserToAddRows = False
            Me.dgvAudit.SelectionMode = DataGridViewSelectionMode.FullRowSelect
            Me.dgvAudit.AutoSizeColumnsMode = DataGridViewAutoSizeColumnsMode.Fill
            Me.dgvAudit.Anchor = AnchorStyles.Top Or AnchorStyles.Left Or AnchorStyles.Right

            Me.lblBefore.Font = New Font("Segoe UI", 9.0F, FontStyle.Bold)
            Me.lblBefore.Location = New Point(30, 405)
            Me.lblBefore.Size = New Size(450, 22)
            Me.lblBefore.Text = "Before values:"
            Me.txtBefore.Location = New Point(30, 428)
            Me.txtBefore.Size = New Size(450, 120)
            Me.txtBefore.Multiline = True
            Me.txtBefore.ReadOnly = True
            Me.txtBefore.ScrollBars = ScrollBars.Vertical
            Me.txtBefore.BackColor = Color.White

            Me.lblAfter.Font = New Font("Segoe UI", 9.0F, FontStyle.Bold)
            Me.lblAfter.Location = New Point(500, 405)
            Me.lblAfter.Size = New Size(480, 22)
            Me.lblAfter.Text = "After values:"
            Me.txtAfter.Location = New Point(500, 428)
            Me.txtAfter.Size = New Size(480, 120)
            Me.txtAfter.Multiline = True
            Me.txtAfter.ReadOnly = True
            Me.txtAfter.ScrollBars = ScrollBars.Vertical
            Me.txtAfter.BackColor = Color.White

            Me.btnExportPdf.Location = New Point(30, 565)
            Me.btnExportPdf.Size = New Size(190, 36)
            Me.btnExportPdf.Text = "Export Audit Trail to PDF"

            Me.btnClose.Location = New Point(235, 565)
            Me.btnClose.Size = New Size(100, 36)
            Me.btnClose.Text = "Close"

            Me.lblStatus.Location = New Point(355, 572)
            Me.lblStatus.Size = New Size(625, 28)
            Me.lblStatus.ForeColor = Color.SeaGreen

            '
            ' AuditLogForm
            '
            Me.ClientSize = New Size(1010, 620)
            Me.StartPosition = FormStartPosition.CenterScreen
            Me.Text = "Audit Trail Viewer"
            Me.Controls.Add(Me.lblHeader)
            Me.Controls.Add(Me.lblFrom)
            Me.Controls.Add(Me.lblTo)
            Me.Controls.Add(Me.lblUser)
            Me.Controls.Add(Me.lblTable)
            Me.Controls.Add(Me.lblAction)
            Me.Controls.Add(Me.dtpFrom)
            Me.Controls.Add(Me.dtpTo)
            Me.Controls.Add(Me.cboUser)
            Me.Controls.Add(Me.cboTable)
            Me.Controls.Add(Me.cboAction)
            Me.Controls.Add(Me.btnApply)
            Me.Controls.Add(Me.dgvAudit)
            Me.Controls.Add(Me.lblBefore)
            Me.Controls.Add(Me.lblAfter)
            Me.Controls.Add(Me.txtBefore)
            Me.Controls.Add(Me.txtAfter)
            Me.Controls.Add(Me.btnExportPdf)
            Me.Controls.Add(Me.btnClose)
            Me.Controls.Add(Me.lblStatus)
            Me.ResumeLayout(False)
            Me.PerformLayout()
        End Sub

    End Class

End Namespace
