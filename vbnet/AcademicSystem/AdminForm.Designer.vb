Namespace AcademicSystem

    Partial Public Class AdminForm

        Friend WithEvents dgvUsers As DataGridView
        Friend WithEvents dgvInstructors As DataGridView
        Friend WithEvents dgvStudents As DataGridView

        Friend lblAddHeader As Label
        Friend lblNewUsername As Label
        Friend lblNewPassword As Label
        Friend lblFirstName As Label
        Friend lblLastName As Label
        Friend lblDepartment As Label
        Friend lblNewEmail As Label
        Friend WithEvents txtNewEmail As TextBox
        Friend WithEvents txtNewUsername As TextBox
        Friend WithEvents txtNewPassword As TextBox
        Friend WithEvents txtFirstName As TextBox
        Friend WithEvents txtLastName As TextBox
        Friend WithEvents txtDepartment As TextBox
        Friend WithEvents btnCreateTeacher As Button
        Friend lblAddStatus As Label

        Friend lblResetHeader As Label
        Friend lblResetUsername As Label
        Friend lblResetPassword As Label
        Friend WithEvents txtResetUsername As TextBox
        Friend WithEvents txtResetPassword As TextBox
        Friend WithEvents btnResetPassword As Button
        Friend lblResetStatus As Label

        Friend tabControl As TabControl
        Friend pageAdd As TabPage
        Friend pageUsers As TabPage
        Friend pageInstructors As TabPage
        Friend pageStudents As TabPage
        Friend pageReset As TabPage
        Friend pageCourses As TabPage
        Friend pageGradebook As TabPage
        Friend lblCourseHeader As Label
        Friend lblCourseCode As Label
        Friend WithEvents txtCourseCode As TextBox
        Friend lblCourseName As Label
        Friend WithEvents txtCourseName As TextBox
        Friend lblCourseInstructor As Label
        Friend WithEvents cboCourseInstructor As ComboBox
        Friend WithEvents btnCreateCourse As Button
        Friend lblCourseStatus As Label
        Friend WithEvents dgvAssignmentTypes As DataGridView
        Friend WithEvents dgvAllGrades As DataGridView
        Friend lblTypeHeader As Label
        Friend lblTypeName As Label
        Friend WithEvents txtTypeName As TextBox
        Friend lblTypeWeight As Label
        Friend WithEvents txtTypeWeight As TextBox
        Friend WithEvents btnAddType As Button
        Friend WithEvents btnEditType As Button
        Friend WithEvents btnDeleteType As Button
        Friend lblTypeStatus As Label
        Friend lblEnrollHeader As Label
        Friend WithEvents cboEnrollStudent As ComboBox
        Friend WithEvents cboEnrollCourse As ComboBox
        Friend WithEvents btnEnroll As Button
        Friend WithEvents btnBulkEnroll As Button
        Friend lblEnrollStatus As Label
        Friend WithEvents txtGradeSearch As TextBox
        Friend WithEvents btnGradeSearch As Button
        Friend bottomPanel As Panel
        Friend WithEvents btnReports As Button
        Friend WithEvents btnAuditLog As Button
        Friend WithEvents btnBackup As Button
        Friend WithEvents btnLogout As Button

        Friend Sub InitializeComponent()
            Me.dgvUsers = New DataGridView()
            Me.dgvInstructors = New DataGridView()
            Me.dgvStudents = New DataGridView()
            Me.lblAddHeader = New Label()
            Me.lblNewUsername = New Label()
            Me.lblNewPassword = New Label()
            Me.lblFirstName = New Label()
            Me.lblLastName = New Label()
            Me.lblDepartment = New Label()
            Me.lblNewEmail = New Label()
            Me.txtNewEmail = New TextBox()
            Me.txtNewUsername = New TextBox()
            Me.txtNewPassword = New TextBox()
            Me.txtFirstName = New TextBox()
            Me.txtLastName = New TextBox()
            Me.txtDepartment = New TextBox()
            Me.btnCreateTeacher = New Button()
            Me.lblAddStatus = New Label()
            Me.lblResetHeader = New Label()
            Me.lblResetUsername = New Label()
            Me.lblResetPassword = New Label()
            Me.txtResetUsername = New TextBox()
            Me.txtResetPassword = New TextBox()
            Me.btnResetPassword = New Button()
            Me.lblResetStatus = New Label()
            Me.tabControl = New TabControl()
            Me.pageAdd = New TabPage()
            Me.pageUsers = New TabPage()
            Me.pageInstructors = New TabPage()
            Me.pageStudents = New TabPage()
            Me.pageReset = New TabPage()
            Me.pageCourses = New TabPage()
            Me.lblCourseHeader = New Label()
            Me.lblCourseCode = New Label()
            Me.txtCourseCode = New TextBox()
            Me.lblCourseName = New Label()
            Me.txtCourseName = New TextBox()
            Me.lblCourseInstructor = New Label()
            Me.cboCourseInstructor = New ComboBox()
            Me.btnCreateCourse = New Button()
            Me.lblCourseStatus = New Label()
            Me.pageGradebook = New TabPage()
            Me.dgvAssignmentTypes = New DataGridView()
            Me.dgvAllGrades = New DataGridView()
            Me.lblTypeHeader = New Label()
            Me.lblTypeName = New Label()
            Me.txtTypeName = New TextBox()
            Me.lblTypeWeight = New Label()
            Me.txtTypeWeight = New TextBox()
            Me.btnAddType = New Button()
            Me.btnEditType = New Button()
            Me.btnDeleteType = New Button()
            Me.lblTypeStatus = New Label()
            Me.lblEnrollHeader = New Label()
            Me.cboEnrollStudent = New ComboBox()
            Me.cboEnrollCourse = New ComboBox()
            Me.btnEnroll = New Button()
            Me.btnBulkEnroll = New Button()
            Me.lblEnrollStatus = New Label()
            Me.txtGradeSearch = New TextBox()
            Me.btnGradeSearch = New Button()
            Me.bottomPanel = New Panel()
            Me.btnReports = New Button()
            Me.btnAuditLog = New Button()
            Me.btnBackup = New Button()
            Me.btnLogout = New Button()
            Me.SuspendLayout()

            '
            ' dgvUsers
            '
            Me.dgvUsers.Dock = DockStyle.Fill
            Me.dgvUsers.ReadOnly = True
            Me.dgvUsers.AllowUserToAddRows = False
            Me.dgvUsers.SelectionMode = DataGridViewSelectionMode.FullRowSelect
            Me.dgvUsers.AutoSizeColumnsMode = DataGridViewAutoSizeColumnsMode.Fill
            '
            ' dgvInstructors
            '
            Me.dgvInstructors.Dock = DockStyle.Fill
            Me.dgvInstructors.ReadOnly = True
            Me.dgvInstructors.AllowUserToAddRows = False
            Me.dgvInstructors.SelectionMode = DataGridViewSelectionMode.FullRowSelect
            Me.dgvInstructors.AutoSizeColumnsMode = DataGridViewAutoSizeColumnsMode.Fill
            '
            ' dgvStudents
            '
            Me.dgvStudents.Dock = DockStyle.Fill
            Me.dgvStudents.ReadOnly = True
            Me.dgvStudents.AllowUserToAddRows = False
            Me.dgvStudents.SelectionMode = DataGridViewSelectionMode.FullRowSelect
            Me.dgvStudents.AutoSizeColumnsMode = DataGridViewAutoSizeColumnsMode.Fill

            '
            ' Add Teacher tab
            '
            Me.lblAddHeader.Font = New Font("Segoe UI", 10.0F, FontStyle.Bold)
            Me.lblAddHeader.Location = New Point(24, 20)
            Me.lblAddHeader.Size = New Size(600, 25)
            Me.lblAddHeader.Text = "Create a Teacher login and Instructor profile in one transaction."

            Me.lblNewUsername.Location = New Point(30, 33)
            Me.lblNewUsername.Size = New Size(140, 25)
            Me.lblNewUsername.Text = "Username:"
            Me.txtNewUsername.Location = New Point(180, 30)
            Me.txtNewUsername.Size = New Size(320, 28)

            Me.lblNewPassword.Location = New Point(30, 73)
            Me.lblNewPassword.Size = New Size(140, 25)
            Me.lblNewPassword.Text = "Password:"
            Me.txtNewPassword.Location = New Point(180, 70)
            Me.txtNewPassword.Size = New Size(320, 28)
            Me.txtNewPassword.UseSystemPasswordChar = True

            Me.lblFirstName.Location = New Point(30, 113)
            Me.lblFirstName.Size = New Size(140, 25)
            Me.lblFirstName.Text = "First name:"
            Me.txtFirstName.Location = New Point(180, 110)
            Me.txtFirstName.Size = New Size(320, 28)

            Me.lblLastName.Location = New Point(30, 153)
            Me.lblLastName.Size = New Size(140, 25)
            Me.lblLastName.Text = "Last name:"
            Me.txtLastName.Location = New Point(180, 150)
            Me.txtLastName.Size = New Size(320, 28)

            Me.lblNewEmail.Location = New Point(30, 193)
            Me.lblNewEmail.Size = New Size(140, 25)
            Me.lblNewEmail.Text = "Email:"
            Me.txtNewEmail.Location = New Point(180, 190)
            Me.txtNewEmail.Size = New Size(320, 28)

            Me.lblDepartment.Location = New Point(30, 233)
            Me.lblDepartment.Size = New Size(140, 25)
            Me.lblDepartment.Text = "Department:"
            Me.txtDepartment.Location = New Point(180, 230)
            Me.txtDepartment.Size = New Size(320, 28)

            Me.btnCreateTeacher.Location = New Point(180, 285)
            Me.btnCreateTeacher.Size = New Size(230, 36)
            Me.btnCreateTeacher.Text = "Create Teacher Account"

            Me.lblAddStatus.Location = New Point(30, 335)
            Me.lblAddStatus.Size = New Size(700, 60)
            Me.lblAddStatus.ForeColor = Color.SeaGreen

            Me.pageAdd.Text = "Add Teacher"
            Me.pageAdd.Controls.Add(Me.lblAddHeader)
            Me.pageAdd.Controls.Add(Me.lblNewUsername)
            Me.pageAdd.Controls.Add(Me.txtNewUsername)
            Me.pageAdd.Controls.Add(Me.lblNewPassword)
            Me.pageAdd.Controls.Add(Me.txtNewPassword)
            Me.pageAdd.Controls.Add(Me.lblFirstName)
            Me.pageAdd.Controls.Add(Me.txtFirstName)
            Me.pageAdd.Controls.Add(Me.lblLastName)
            Me.pageAdd.Controls.Add(Me.txtLastName)
            Me.pageAdd.Controls.Add(Me.lblNewEmail)
            Me.pageAdd.Controls.Add(Me.txtNewEmail)
            Me.pageAdd.Controls.Add(Me.lblDepartment)
            Me.pageAdd.Controls.Add(Me.txtDepartment)
            Me.pageAdd.Controls.Add(Me.btnCreateTeacher)
            Me.pageAdd.Controls.Add(Me.lblAddStatus)

            '
            ' List tabs
            '
            Me.pageUsers.Text = "Users"
            Me.pageUsers.Controls.Add(Me.dgvUsers)
            Me.pageInstructors.Text = "Instructors"
            Me.pageInstructors.Controls.Add(Me.dgvInstructors)
            Me.pageStudents.Text = "Students"
            Me.pageStudents.Controls.Add(Me.dgvStudents)

            '
            ' Reset Password tab
            '
            Me.lblResetHeader.Font = New Font("Segoe UI", 10.0F, FontStyle.Bold)
            Me.lblResetHeader.Location = New Point(24, 20)
            Me.lblResetHeader.Size = New Size(700, 25)
            Me.lblResetHeader.Text = "Passwords are never stored in plain text. A new salted PBKDF2 hash is generated."

            Me.lblResetUsername.Location = New Point(30, 63)
            Me.lblResetUsername.Size = New Size(140, 25)
            Me.lblResetUsername.Text = "Username:"
            Me.txtResetUsername.Location = New Point(180, 60)
            Me.txtResetUsername.Size = New Size(320, 28)

            Me.lblResetPassword.Location = New Point(30, 103)
            Me.lblResetPassword.Size = New Size(140, 25)
            Me.lblResetPassword.Text = "New password:"
            Me.txtResetPassword.Location = New Point(180, 100)
            Me.txtResetPassword.Size = New Size(320, 28)
            Me.txtResetPassword.UseSystemPasswordChar = True

            Me.btnResetPassword.Location = New Point(180, 155)
            Me.btnResetPassword.Size = New Size(230, 36)
            Me.btnResetPassword.Text = "Reset Password"

            Me.lblResetStatus.Location = New Point(30, 205)
            Me.lblResetStatus.Size = New Size(700, 50)
            Me.lblResetStatus.ForeColor = Color.SeaGreen

            Me.pageReset.Text = "Reset Password"
            Me.pageReset.Controls.Add(Me.lblResetHeader)
            Me.pageReset.Controls.Add(Me.lblResetUsername)
            Me.pageReset.Controls.Add(Me.txtResetUsername)
            Me.pageReset.Controls.Add(Me.lblResetPassword)
            Me.pageReset.Controls.Add(Me.txtResetPassword)
            Me.pageReset.Controls.Add(Me.btnResetPassword)
            Me.pageReset.Controls.Add(Me.lblResetStatus)

            '
            ' Courses tab (validated course creation)
            '
            Me.lblCourseHeader.Font = New Font("Segoe UI", 10.0F, FontStyle.Bold)
            Me.lblCourseHeader.Location = New Point(24, 20)
            Me.lblCourseHeader.Size = New Size(700, 25)
            Me.lblCourseHeader.Text = "Course codes must match CS101-style format and be unique."

            Me.lblCourseCode.Location = New Point(30, 63)
            Me.lblCourseCode.Size = New Size(140, 25)
            Me.lblCourseCode.Text = "Course code:"
            Me.txtCourseCode.Location = New Point(180, 60)
            Me.txtCourseCode.Size = New Size(320, 28)

            Me.lblCourseName.Location = New Point(30, 103)
            Me.lblCourseName.Size = New Size(140, 25)
            Me.lblCourseName.Text = "Course name:"
            Me.txtCourseName.Location = New Point(180, 100)
            Me.txtCourseName.Size = New Size(320, 28)

            Me.lblCourseInstructor.Location = New Point(30, 143)
            Me.lblCourseInstructor.Size = New Size(140, 25)
            Me.lblCourseInstructor.Text = "Instructor:"
            Me.cboCourseInstructor.Location = New Point(180, 140)
            Me.cboCourseInstructor.Size = New Size(320, 28)
            Me.cboCourseInstructor.DropDownStyle = ComboBoxStyle.DropDownList

            Me.btnCreateCourse.Location = New Point(180, 195)
            Me.btnCreateCourse.Size = New Size(230, 36)
            Me.btnCreateCourse.Text = "Create Course"

            Me.lblCourseStatus.Location = New Point(30, 245)
            Me.lblCourseStatus.Size = New Size(700, 60)
            Me.lblCourseStatus.ForeColor = Color.SeaGreen

            Me.pageCourses.Text = "Courses"
            Me.pageCourses.Controls.Add(Me.lblCourseHeader)
            Me.pageCourses.Controls.Add(Me.lblCourseCode)
            Me.pageCourses.Controls.Add(Me.txtCourseCode)
            Me.pageCourses.Controls.Add(Me.lblCourseName)
            Me.pageCourses.Controls.Add(Me.txtCourseName)
            Me.pageCourses.Controls.Add(Me.lblCourseInstructor)
            Me.pageCourses.Controls.Add(Me.cboCourseInstructor)
            Me.pageCourses.Controls.Add(Me.btnCreateCourse)
            Me.pageCourses.Controls.Add(Me.lblCourseStatus)

            '
            ' Gradebook tab
            '
            Me.lblTypeHeader.Font = New Font("Segoe UI", 10.0F, FontStyle.Bold)
            Me.lblTypeHeader.Location = New Point(14, 12)
            Me.lblTypeHeader.Size = New Size(500, 24)
            Me.lblTypeHeader.Text = "Assignment Types (add / edit / delete)"

            Me.dgvAssignmentTypes.AllowUserToAddRows = False
            Me.dgvAssignmentTypes.AutoSizeColumnsMode = DataGridViewAutoSizeColumnsMode.Fill
            Me.dgvAssignmentTypes.Location = New Point(14, 38)
            Me.dgvAssignmentTypes.Size = New Size(870, 150)
            Me.dgvAssignmentTypes.ReadOnly = True
            Me.dgvAssignmentTypes.SelectionMode = DataGridViewSelectionMode.FullRowSelect

            Me.lblTypeName.Location = New Point(14, 202)
            Me.lblTypeName.Size = New Size(110, 25)
            Me.lblTypeName.Text = "Type name:"
            Me.txtTypeName.Location = New Point(120, 198)
            Me.txtTypeName.Size = New Size(210, 28)
            Me.lblTypeWeight.Location = New Point(350, 202)
            Me.lblTypeWeight.Size = New Size(90, 25)
            Me.lblTypeWeight.Text = "Weight %:"
            Me.txtTypeWeight.Location = New Point(440, 198)
            Me.txtTypeWeight.Size = New Size(90, 28)

            Me.btnAddType.Location = New Point(570, 196)
            Me.btnAddType.Size = New Size(90, 32)
            Me.btnAddType.Text = "Add"
            Me.btnEditType.Location = New Point(670, 196)
            Me.btnEditType.Size = New Size(90, 32)
            Me.btnEditType.Text = "Edit"
            Me.btnDeleteType.Location = New Point(770, 196)
            Me.btnDeleteType.Size = New Size(90, 32)
            Me.btnDeleteType.Text = "Delete"
            Me.lblTypeStatus.Location = New Point(14, 234)
            Me.lblTypeStatus.Size = New Size(870, 30)
            Me.lblTypeStatus.ForeColor = Color.SeaGreen

            Me.lblEnrollHeader.Font = New Font("Segoe UI", 10.0F, FontStyle.Bold)
            Me.lblEnrollHeader.Location = New Point(14, 270)
            Me.lblEnrollHeader.Size = New Size(500, 24)
            Me.lblEnrollHeader.Text = "Enrollment (uses sp_EnrollStudent with transaction handling)"

            Me.cboEnrollStudent.Location = New Point(14, 302)
            Me.cboEnrollStudent.Size = New Size(280, 28)
            Me.cboEnrollStudent.DropDownStyle = ComboBoxStyle.DropDownList
            Me.cboEnrollCourse.Location = New Point(310, 302)
            Me.cboEnrollCourse.Size = New Size(280, 28)
            Me.cboEnrollCourse.DropDownStyle = ComboBoxStyle.DropDownList
            Me.btnEnroll.Location = New Point(610, 300)
            Me.btnEnroll.Size = New Size(140, 32)
            Me.btnEnroll.Text = "Enroll Student"
            Me.btnBulkEnroll.Location = New Point(760, 300)
            Me.btnBulkEnroll.Size = New Size(150, 32)
            Me.btnBulkEnroll.Text = "Bulk Enroll"
            Me.lblEnrollStatus.Location = New Point(14, 342)
            Me.lblEnrollStatus.Size = New Size(870, 30)
            Me.lblEnrollStatus.ForeColor = Color.SeaGreen

            Me.txtGradeSearch.Location = New Point(14, 376)
            Me.txtGradeSearch.Size = New Size(320, 28)
            Me.btnGradeSearch.Location = New Point(350, 374)
            Me.btnGradeSearch.Size = New Size(140, 32)
            Me.btnGradeSearch.Text = "Search Grades"

            Me.dgvAllGrades.AllowUserToAddRows = False
            Me.dgvAllGrades.AutoSizeColumnsMode = DataGridViewAutoSizeColumnsMode.Fill
            Me.dgvAllGrades.Location = New Point(14, 414)
            Me.dgvAllGrades.Size = New Size(870, 145)
            Me.dgvAllGrades.ReadOnly = True
            Me.dgvAllGrades.SelectionMode = DataGridViewSelectionMode.FullRowSelect

            Me.pageGradebook.Text = "Gradebook"
            Me.pageGradebook.Controls.Add(Me.lblTypeHeader)
            Me.pageGradebook.Controls.Add(Me.dgvAssignmentTypes)
            Me.pageGradebook.Controls.Add(Me.lblTypeName)
            Me.pageGradebook.Controls.Add(Me.txtTypeName)
            Me.pageGradebook.Controls.Add(Me.lblTypeWeight)
            Me.pageGradebook.Controls.Add(Me.txtTypeWeight)
            Me.pageGradebook.Controls.Add(Me.btnAddType)
            Me.pageGradebook.Controls.Add(Me.btnEditType)
            Me.pageGradebook.Controls.Add(Me.btnDeleteType)
            Me.pageGradebook.Controls.Add(Me.lblTypeStatus)
            Me.pageGradebook.Controls.Add(Me.lblEnrollHeader)
            Me.pageGradebook.Controls.Add(Me.cboEnrollStudent)
            Me.pageGradebook.Controls.Add(Me.cboEnrollCourse)
            Me.pageGradebook.Controls.Add(Me.btnEnroll)
            Me.pageGradebook.Controls.Add(Me.btnBulkEnroll)
            Me.pageGradebook.Controls.Add(Me.lblEnrollStatus)
            Me.pageGradebook.Controls.Add(Me.txtGradeSearch)
            Me.pageGradebook.Controls.Add(Me.btnGradeSearch)
            Me.pageGradebook.Controls.Add(Me.dgvAllGrades)
            Me.dgvAllGrades.Anchor = AnchorStyles.Top Or AnchorStyles.Bottom Or AnchorStyles.Left Or AnchorStyles.Right
            '
            ' tabControl
            '
            Me.tabControl.Dock = DockStyle.Fill
            Me.tabControl.TabPages.Add(Me.pageAdd)
            Me.tabControl.TabPages.Add(Me.pageUsers)
            Me.tabControl.TabPages.Add(Me.pageInstructors)
            Me.tabControl.TabPages.Add(Me.pageStudents)
            Me.tabControl.TabPages.Add(Me.pageReset)
            Me.tabControl.TabPages.Add(Me.pageCourses)
            Me.tabControl.TabPages.Add(Me.pageGradebook)

            '
            ' bottomPanel
            '
            Me.bottomPanel.Dock = DockStyle.Bottom
            Me.bottomPanel.Height = 48
            Me.btnLogout.Location = New Point(14, 10)
            Me.btnLogout.Size = New Size(100, 30)
            Me.btnLogout.Text = "Logout"
            Me.btnReports.Location = New Point(130, 10)
            Me.btnReports.Size = New Size(120, 30)
            Me.btnReports.Text = "Reports"
            Me.btnAuditLog.Location = New Point(265, 10)
            Me.btnAuditLog.Size = New Size(120, 30)
            Me.btnAuditLog.Text = "Audit Trail"
            Me.btnBackup.Location = New Point(400, 10)
            Me.btnBackup.Size = New Size(110, 30)
            Me.btnBackup.Text = "Backup"
            Me.bottomPanel.Controls.Add(Me.btnLogout)
            Me.bottomPanel.Controls.Add(Me.btnReports)
            Me.bottomPanel.Controls.Add(Me.btnAuditLog)
            Me.bottomPanel.Controls.Add(Me.btnBackup)

            '
            ' AdminForm
            '
            Me.ClientSize = New Size(924, 602)
            Me.Controls.Add(Me.tabControl)
            Me.Controls.Add(Me.bottomPanel)
            Me.Name = "AdminForm"
            Me.StartPosition = FormStartPosition.CenterScreen
            Me.Text = "Admin Management"
            Me.ResumeLayout(False)
            Me.PerformLayout()
        End Sub

    End Class

End Namespace
