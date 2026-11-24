Namespace AcademicSystem

    <System.ComponentModel.DesignerCategory("Form")>
    Partial Public Class StudentForm
        Inherits Form

        Public Sub New()
            InitializeComponent()
            AddHandler logout.Click, Sub(sender As Object, e As EventArgs) Close()

            Dim designTime As Boolean = (System.ComponentModel.LicenseManager.UsageMode = System.ComponentModel.LicenseUsageMode.Designtime)

            Text = If(designTime, "Student Portal (Design Preview)", "Student Portal - " & Session.Username)

            If Not designTime Then
                Dim parameters As New Dictionary(Of String, Object) From {{"@userId", Session.UserId}}
                Dim profile = Db.FetchTable(
                    "SELECT s.student_id, s.first_name, s.last_name, s.date_of_birth " &
                    "FROM students s WHERE s.user_id = @userId", parameters)

                If profile.Rows.Count > 0 Then
                    Dim row = profile.Rows(0)
                    header.Text = Convert.ToString(row("first_name")) & " " &
                                  Convert.ToString(row("last_name")) &
                                  "  |  Birth date: " & Convert.ToString(row("date_of_birth")) &
                                  "  |  Student ID: " & Convert.ToString(row("student_id"))
                Else
                    header.Text = "No student profile is linked to this account."
                End If

                grid.DataSource = Db.FetchTable(
                    "SELECT c.course_code AS 'Code', c.course_name AS 'Course', " &
                    "i.last_name AS 'Instructor', e.enrollment_date AS 'Enrolled On' " &
                    "FROM enrollments e JOIN students s ON s.student_id = e.student_id " &
                    "JOIN courses c ON c.course_id = e.course_id " &
                    "LEFT JOIN instructors i ON i.instructor_id = c.instructor_id " &
                    "WHERE s.user_id = @userId ORDER BY c.course_code", parameters)
            End If
        End Sub

    End Class

End Namespace
