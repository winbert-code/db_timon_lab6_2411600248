Namespace AcademicSystem

    Partial Public Class StudentForm

        Friend WithEvents header As Label
        Friend WithEvents grid As DataGridView
        Friend WithEvents bottomPanel As Panel
        Friend WithEvents logout As Button

        Friend Sub InitializeComponent()
            Me.header = New Label()
            Me.grid = New DataGridView()
            Me.bottomPanel = New Panel()
            Me.logout = New Button()
            Me.SuspendLayout()
            '
            ' header
            '
            Me.header.Dock = DockStyle.Top
            Me.header.Font = New Font("Segoe UI", 11.0F, FontStyle.Bold)
            Me.header.Height = 55
            Me.header.Padding = New Padding(14)
            Me.header.Text = "Student Portal (design preview)"
            '
            ' grid
            '
            Me.grid.AllowUserToAddRows = False
            Me.grid.AutoSizeColumnsMode = DataGridViewAutoSizeColumnsMode.Fill
            Me.grid.Dock = DockStyle.Fill
            Me.grid.ReadOnly = True
            '
            ' bottomPanel
            '
            Me.bottomPanel.Dock = DockStyle.Bottom
            Me.bottomPanel.Height = 48
            '
            ' logout
            '
            Me.logout.Location = New Point(14, 10)
            Me.logout.Size = New Size(100, 30)
            Me.logout.Text = "Logout"
            Me.bottomPanel.Controls.Add(Me.logout)
            '
            ' StudentForm
            '
            Me.ClientSize = New Size(844, 482)
            Me.Controls.Add(Me.grid)
            Me.Controls.Add(Me.header)
            Me.Controls.Add(Me.bottomPanel)
            Me.Name = "StudentForm"
            Me.StartPosition = FormStartPosition.CenterScreen
            Me.Text = "Student Portal"
            Me.ResumeLayout(False)
            Me.PerformLayout()
        End Sub

    End Class

End Namespace
