Namespace AcademicSystem

    <System.ComponentModel.DesignerCategory("Form")>
    Partial Public Class StudentDashboard
        Inherits Form

        Private _studentId As Integer

        Public Sub New()
            InitializeComponent()

            Dim designTime As Boolean = (System.ComponentModel.LicenseManager.UsageMode =
                                          System.ComponentModel.LicenseUsageMode.Designtime)

            If designTime Then
                header.Text = "Student Dashboard (Design Preview)"
                Return
            End If

            If Session.RoleId <> 3 Then
                Throw New UnauthorizedAccessException("Student role is required to open this form.")
            End If

            Text = "Student Dashboard - " & Session.Username
            SessionUi.AddStatusBar(Me)

            AddHandler btnLogout.Click, Sub(sender As Object, e As EventArgs) Close()
            AddHandler btnSearch.Click, AddressOf BtnSearch_Click
            AddHandler txtSearch.KeyDown, AddressOf TxtSearch_KeyDown

            LoadProfile()
            RefreshGrades()
            RefreshAverages()
        End Sub

        Private Sub LoadProfile()
            Dim parameters As New Dictionary(Of String, Object) From {{"@userId", Session.UserId}}
            Dim profile = Db.FetchTable(
                "SELECT student_id, first_name, last_name FROM student_own_profile WHERE user_id = @userId",
                parameters)

            If profile.Rows.Count > 0 Then
                Dim row = profile.Rows(0)
                _studentId = Convert.ToInt32(row("student_id"))
                header.Text = "Welcome, " & Convert.ToString(row("first_name")) & " " &
                              Convert.ToString(row("last_name")) &
                              "  |  Student ID: " & _studentId &
                              "  |  Your grades and course averages"
            Else
                header.Text = "No student profile is linked to this account."
                _studentId = -1
            End If
        End Sub

        Private Sub RefreshGrades()
            If _studentId <= 0 Then Return

            Dim sql As String =
                "SELECT course_code AS 'Course Code', course_name AS 'Course', " &
                "type_name AS 'Assignment', grade AS 'Grade', " &
                "date_recorded AS 'Recorded' " &
                "FROM student_grade_summary WHERE student_id = @studentId"

            Dim parameters As New Dictionary(Of String, Object) From {{"@studentId", _studentId}}

            Dim search As String = txtSearch.Text.Trim()
            If search.Length > 0 Then
                sql &= " AND (course_code LIKE @q1 OR course_name LIKE @q1 OR type_name LIKE @q1)"
                parameters.Add("@q1", InputValidator.SafeLike(search))
            End If

            sql &= " ORDER BY course_code, type_name"
            dgvGrades.DataSource = Db.FetchTable(sql, parameters)
        End Sub

        Private Sub RefreshAverages()
            If _studentId <= 0 Then Return

            Dim parameters As New Dictionary(Of String, Object) From {{"@studentId", _studentId}}
            dgvAverages.DataSource = Db.FetchTable(
                "SELECT course_code AS 'Course Code', course_name AS 'Course', " &
                "average_grade AS 'Average Grade', grades_recorded AS 'Grades Recorded' " &
                "FROM student_course_averages " &
                "WHERE student_id = @studentId ORDER BY course_code", parameters)
        End Sub

        Private Sub BtnSearch_Click(sender As Object, e As EventArgs)
            RefreshGrades()
            lblStatus.Text = "Search complete."
        End Sub

        Private Sub TxtSearch_KeyDown(sender As Object, e As KeyEventArgs)
            If e.KeyCode = Keys.Enter Then
                RefreshGrades()
                e.Handled = True
            End If
        End Sub

    End Class

End Namespace
