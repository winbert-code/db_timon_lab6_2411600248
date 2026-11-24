Imports System.Linq

Namespace AcademicSystem

    ' Global activity filter, inactivity timer and status-bar helper.
    Friend Module SessionMonitor

        Private WithEvents _timer As Timer

        Friend Sub Install()
            If _timer IsNot Nothing Then Return
            _timer = New Timer() With {.Interval = 15000}
            _timer.Start()
        End Sub

        Private Sub _timer_Tick(sender As Object, e As EventArgs) Handles _timer.Tick
            If String.IsNullOrEmpty(Session.SessionId) Then Return

            For Each form As Form In Application.OpenForms.Cast(Of Form)().ToList()
                SessionUi.RefreshStatus(form)
            Next

            If Session.IsTimedOut() Then
                Session.EndSession("TIMEOUT")
                For Each form As Form In Application.OpenForms.Cast(Of Form)().ToList()
                    If form.Name <> "LoginForm" Then form.Close()
                Next
            End If
        End Sub

    End Module

    Friend Module SessionUi

        Friend Sub AddStatusBar(form As Form)
            If form Is Nothing OrElse form.Controls.ContainsKey("sessionStatus") Then Return

            Dim strip As New StatusStrip()
            strip.Name = "sessionStatus"
            strip.Dock = DockStyle.Bottom
            strip.SizingGrip = False

            Dim label As New ToolStripStatusLabel()
            label.Name = "sessionStatusLabel"
            label.Spring = True
            label.TextAlign = System.Drawing.ContentAlignment.MiddleLeft
            strip.Items.Add(label)

            form.Controls.Add(strip)
            RefreshStatus(form)
        End Sub

        Friend Sub RefreshStatus(form As Form)
            If form Is Nothing OrElse Not form.Controls.ContainsKey("sessionStatus") Then Return

            Dim strip As StatusStrip = TryCast(form.Controls("sessionStatus"), StatusStrip)
            If strip Is Nothing Then Return
            Dim label As ToolStripItem = strip.Items("sessionStatusLabel")
            If label Is Nothing Then Return

            Dim idleMinutes As Integer = 0
            If Session.LastActivity <> DateTime.MinValue Then
                idleMinutes = Convert.ToInt32((DateTime.Now - Session.LastActivity).TotalMinutes)
            End If

            Dim loginText As String = If(Session.LoginTime = DateTime.MinValue,
                                         "--:--", Session.LoginTime.ToString("HH:mm"))
            label.Text = "User: " & If(Session.Username, "-") &
                         "   |   Role: " & If(Session.RoleName, "-") &
                         "   |   Login: " & loginText &
                         "   |   Idle: " & idleMinutes & " min" &
                         "   |   Auto logout in: " &
                         Math.Max(0, Session.InactivityMinutes - idleMinutes) & " min"
        End Sub

    End Module

End Namespace
