Namespace AcademicSystem

    <System.ComponentModel.DesignerCategory("Form")>
    Partial Public Class TeacherForm
        Inherits Form

        Public Sub New()
            InitializeComponent()
            AddHandler logout.Click, Sub(sender As Object, e As EventArgs) Close()

            Dim designTime As Boolean = (System.ComponentModel.LicenseManager.UsageMode = System.ComponentModel.LicenseUsageMode.Designtime)

            Text = If(designTime, "Teacher Portal (Design Preview)", "Teacher Portal - " & Session.Username)

            If Not designTime Then
                Dim parameters As New Dictionary(Of String, Object) From {{"@userId", Session.UserId}}
                Dim profile = Db.FetchTable(
                    "SELECT i.instructor_id, i.first_name, i.last_name, i.department " &
                    "FROM instructors i WHERE i.user_id = @userId", parameters)

                If profile.Rows.Count > 0 Then
                    Dim row = profile.Rows(0)
                    header.Text = Convert.ToString(row("first_name")) & " " &
                                  Convert.ToString(row("last_name")) &
                                  "  |  Department: " & Convert.ToString(row("department")) &
                                  "  |  Instructor ID: " & Convert.ToString(row("instructor_id"))
                Else
                    header.Text = "No instructor profile is linked to this account."
                End If

                grid.DataSource = Db.FetchTable(
                    "SELECT c.course_code AS 'Code', c.course_name AS 'Course', " &
                    "(SELECT COUNT(*) FROM enrollments e WHERE e.course_id = c.course_id) AS 'Enrolled' " &
                    "FROM courses c JOIN instructors i ON i.instructor_id = c.instructor_id " &
                    "WHERE i.user_id = @userId ORDER BY c.course_code", parameters)
            End If
        End Sub

    End Class

End Namespace
