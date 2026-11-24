Imports System.Data
Imports MySqlConnector

Namespace AcademicSystem

    <System.ComponentModel.DesignerCategory("Form")>
    Partial Public Class TeacherDashboard
        Inherits Form

        Public Sub New()
            InitializeComponent()

            Dim designTime As Boolean = (System.ComponentModel.LicenseManager.UsageMode =
                                          System.ComponentModel.LicenseUsageMode.Designtime)

            If designTime Then
                header.Text = "Teacher Dashboard (Design Preview)"
                Return
            End If

            If Session.RoleId <> 2 Then
                Throw New UnauthorizedAccessException("Teacher role is required to open this form.")
            End If

            Text = "Teacher Dashboard - " & Session.Username
            header.Text = "Welcome, " & Session.Username &
                          "  |  Course overview and gradebook entry"
            SessionUi.AddStatusBar(Me)

            AddHandler btnLogout.Click, Sub(sender As Object, e As EventArgs) Close()
            AddHandler btnReports.Click, AddressOf BtnReports_Click
            AddHandler btnSaveGrade.Click, AddressOf BtnSaveGrade_Click
            AddHandler btnCalculate.Click, AddressOf BtnCalculate_Click
            AddHandler btnSearch.Click, AddressOf BtnSearch_Click
            AddHandler cboCourse.SelectedIndexChanged, AddressOf CboCourse_SelectedIndexChanged
            AddHandler txtSearch.KeyDown, AddressOf TxtSearch_KeyDown

            LoadCombos()
            RefreshOverview()
        End Sub

        Private Sub LoadCombos()
            Dim parameters As New Dictionary(Of String, Object) From {{"@userId", Session.UserId}}

            Dim courses = Db.FetchTable(
                "SELECT c.course_id AS Value, " &
                "CONCAT(c.course_code, ' - ', c.course_name) AS Display " &
                "FROM courses c JOIN instructors i ON i.instructor_id = c.instructor_id " &
                "WHERE i.user_id = @userId ORDER BY c.course_code", parameters)
            cboCourse.DataSource = courses
            cboCourse.DisplayMember = "Display"
            cboCourse.ValueMember = "Value"

            Dim types = Db.FetchTable(
                "SELECT type_id AS Value, type_name AS Display " &
                "FROM assignment_types ORDER BY type_id")
            cboType.DataSource = types
            cboType.DisplayMember = "Display"
            cboType.ValueMember = "Value"

            LoadStudents()
        End Sub

        Private Sub LoadStudents()
            If cboCourse.SelectedValue Is Nothing Then Return

            Dim parameters As New Dictionary(Of String, Object) From {
                {"@courseId", Convert.ToInt32(cboCourse.SelectedValue)}
            }
            Dim students = Db.FetchTable(
                "SELECT s.student_id AS Value, " &
                "CONCAT(s.first_name, ' ', s.last_name) AS Display " &
                "FROM enrollments e JOIN students s ON s.student_id = e.student_id " &
                "WHERE e.course_id = @courseId ORDER BY Display", parameters)

            cboStudent.DataSource = students
            cboStudent.DisplayMember = "Display"
            cboStudent.ValueMember = "Value"
        End Sub

        Private Sub CboCourse_SelectedIndexChanged(sender As Object, e As EventArgs)
            If Not IsDesignTime() Then LoadStudents()
        End Sub

        Private Function IsDesignTime() As Boolean
            Return System.ComponentModel.LicenseManager.UsageMode =
                   System.ComponentModel.LicenseUsageMode.Designtime
        End Function

        Private Sub RefreshOverview()
            Dim sql As String =
                "SELECT course_code AS 'Course', type_name AS 'Assignment', " &
                "submissions AS 'Submissions', average_grade AS 'Average Grade' " &
                "FROM teacher_course_overview WHERE user_id = @userId " &
                "ORDER BY course_code, type_name"

            Dim parameters As New Dictionary(Of String, Object) From {{"@userId", Session.UserId}}

            Dim search As String = txtSearch.Text.Trim()
            If search.Length > 0 Then
                sql = sql.Replace("ORDER BY", "AND (course_code LIKE @q1 OR course_name LIKE @q1 OR type_name LIKE @q1) ORDER BY")
                parameters.Add("@q1", InputValidator.SafeLike(search))
            End If

            dgvOverview.DataSource = Db.FetchTable(sql, parameters)
        End Sub

        Private Sub BtnSearch_Click(sender As Object, e As EventArgs)
            RefreshOverview()
            lblStatus.Text = "Search complete."
        End Sub

        Private Sub TxtSearch_KeyDown(sender As Object, e As KeyEventArgs)
            If e.KeyCode = Keys.Enter Then
                RefreshOverview()
                e.Handled = True
            End If
        End Sub

        Private Sub BtnSaveGrade_Click(sender As Object, e As EventArgs)
            lblStatus.ForeColor = Color.Firebrick

            If cboStudent.SelectedValue Is Nothing OrElse cboCourse.SelectedValue Is Nothing OrElse
               cboType.SelectedValue Is Nothing Then
                lblStatus.Text = "Select a course, a student and an assignment type."
                Return
            End If

            Dim grade As Decimal
            If Not Decimal.TryParse(txtGrade.Text.Trim(), grade) Then
                lblStatus.Text = "Enter a numeric grade between 0 and 100."
                Return
            End If
            If grade < 0 OrElse grade > 100 Then
                lblStatus.Text = "The CHECK constraint allows grades only from 0 to 100."
                Return
            End If

            Dim parameters As New Dictionary(Of String, Object) From {
                {"@studentId", Convert.ToInt32(cboStudent.SelectedValue)},
                {"@courseId", Convert.ToInt32(cboCourse.SelectedValue)},
                {"@typeId", Convert.ToInt32(cboType.SelectedValue)},
                {"@grade", grade}
            }

            Dim rows As Integer = Db.Execute(
                "INSERT INTO grades (student_id, course_id, type_id, grade) " &
                "VALUES (@studentId, @courseId, @typeId, @grade) " &
                "ON DUPLICATE KEY UPDATE grade = VALUES(grade), date_recorded = CURRENT_TIMESTAMP",
                parameters)

            lblStatus.ForeColor = Color.SeaGreen
            lblStatus.Text = "Grade saved (rows affected: " & rows & ")."
            txtGrade.Clear()
            RefreshOverview()
        End Sub

        Private Sub BtnCalculate_Click(sender As Object, e As EventArgs)
            If cboStudent.SelectedValue Is Nothing Then
                lblStatus.ForeColor = Color.Firebrick
                lblStatus.Text = "Select a student first."
                Return
            End If

            Dim studentId As Integer = Convert.ToInt32(cboStudent.SelectedValue)

            Try
                Using connection = Db.GetConnection()
                    Using command As New MySqlCommand("sp_CalculateCourseGrade", connection)
                        command.CommandType = CommandType.StoredProcedure
                        command.Parameters.AddWithValue("@p_student_id", studentId)

                        Dim outputParam As New MySqlParameter("@p_final_grade", MySqlDbType.Decimal)
                        outputParam.Direction = ParameterDirection.Output
                        outputParam.Scale = 2
                        command.Parameters.Add(outputParam)

                        connection.Open()
                        command.ExecuteNonQuery()
                        Dim finalGrade As Decimal = Convert.ToDecimal(outputParam.Value)
                        lblStatus.ForeColor = Color.SeaGreen
                        lblStatus.Text = "Weighted final grade: " & finalGrade.ToString("0.00") &
                                         "  (override by entering a different grade above)."
                    End Using
                End Using
            Catch ex As Exception
                lblStatus.ForeColor = Color.Firebrick
                lblStatus.Text = "Calculation failed: " & ex.Message
            End Try
        End Sub

        Private Sub BtnReports_Click(sender As Object, e As EventArgs)
            Dim reports As New ReportsForm()
            AddHandler reports.FormClosed,
                Sub(sender2 As Object, e2 As FormClosedEventArgs) Show()
            Hide()
            reports.Show()
        End Sub

    End Class

End Namespace
