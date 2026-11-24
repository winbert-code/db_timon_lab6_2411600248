Namespace AcademicSystem

    Partial Public Class LoginForm

        Friend WithEvents txtUsername As TextBox
        Friend WithEvents txtPassword As TextBox
        Friend WithEvents lblStatus As Label
        Friend WithEvents btnLogin As Button
        Friend WithEvents lblTitle As Label
        Friend WithEvents lblUser As Label
        Friend WithEvents lblPass As Label
        Friend WithEvents lblHint As Label

        Friend Sub InitializeComponent()
            Me.txtUsername = New TextBox()
            Me.txtPassword = New TextBox()
            Me.lblStatus = New Label()
            Me.btnLogin = New Button()
            Me.lblTitle = New Label()
            Me.lblUser = New Label()
            Me.lblPass = New Label()
            Me.lblHint = New Label()
            Me.SuspendLayout()
            '
            ' lblTitle
            '
            Me.lblTitle.Font = New Font("Segoe UI", 14.0F, FontStyle.Bold)
            Me.lblTitle.Location = New Point(24, 18)
            Me.lblTitle.Size = New Size(400, 30)
            Me.lblTitle.Text = "ACADEMIC SYSTEM LOGIN"
            '
            ' lblUser
            '
            Me.lblUser.Location = New Point(24, 70)
            Me.lblUser.Size = New Size(90, 25)
            Me.lblUser.Text = "Username:"
            '
            ' txtUsername
            '
            Me.txtUsername.Location = New Point(120, 67)
            Me.txtUsername.Size = New Size(290, 28)
            '
            ' lblPass
            '
            Me.lblPass.Location = New Point(24, 110)
            Me.lblPass.Size = New Size(90, 25)
            Me.lblPass.Text = "Password:"
            '
            ' txtPassword
            '
            Me.txtPassword.Location = New Point(120, 107)
            Me.txtPassword.Size = New Size(290, 28)
            Me.txtPassword.UseSystemPasswordChar = True
            '
            ' btnLogin
            '
            Me.btnLogin.Location = New Point(120, 155)
            Me.btnLogin.Size = New Size(120, 34)
            Me.btnLogin.Text = "Login"
            '
            ' lblStatus
            '
            Me.lblStatus.ForeColor = Color.Firebrick
            Me.lblStatus.Location = New Point(24, 205)
            Me.lblStatus.Size = New Size(400, 25)
            '
            ' lblHint
            '
            Me.lblHint.Font = New Font("Segoe UI", 8.0F)
            Me.lblHint.ForeColor = Color.DimGray
            Me.lblHint.Location = New Point(24, 235)
            Me.lblHint.Size = New Size(400, 35)
            Me.lblHint.Text = "Demo accounts: admin / Admin@123  |  teacher1 / Teacher@123  |  student1 / Student@123"
            '
            ' LoginForm
            '
            Me.AcceptButton = Me.btnLogin
            Me.ClientSize = New Size(444, 262)
            Me.Controls.Add(Me.lblTitle)
            Me.Controls.Add(Me.lblUser)
            Me.Controls.Add(Me.txtUsername)
            Me.Controls.Add(Me.lblPass)
            Me.Controls.Add(Me.txtPassword)
            Me.Controls.Add(Me.btnLogin)
            Me.Controls.Add(Me.lblStatus)
            Me.Controls.Add(Me.lblHint)
            Me.FormBorderStyle = FormBorderStyle.FixedDialog
            Me.MaximizeBox = False
            Me.Name = "LoginForm"
            Me.StartPosition = FormStartPosition.CenterScreen
            Me.Text = "Academic System - Login"
            Me.ResumeLayout(False)
            Me.PerformLayout()
        End Sub

    End Class

End Namespace
