Imports System.IO
Imports System.Text

Namespace AcademicSystem

    ' Small dependency-free PDF writer used by the Audit Trail Viewer.
    ' Produces a valid, text-based PDF (Helvetica) with pagination.
    Friend Module PdfExporter

        Friend Sub Export(title As String, lines As IEnumerable(Of String), filePath As String)
            Dim wrapped As New List(Of String)()
            wrapped.Add(title)
            wrapped.Add("Generated: " & DateTime.Now.ToString("yyyy-MM-dd HH:mm"))
            wrapped.Add("")
            For Each line As String In lines
                If line.Length <= 94 Then
                    wrapped.Add(line)
                Else
                    Dim remaining As String = line
                    While remaining.Length > 94
                        wrapped.Add(remaining.Substring(0, 94))
                        remaining = remaining.Substring(94)
                    End While
                    wrapped.Add(remaining)
                End If
            Next

            Dim pages As New List(Of List(Of String))()
            For start As Integer = 0 To wrapped.Count - 1 Step 50
                Dim pageLines As New List(Of String)()
                For index As Integer = start To Math.Min(start + 49, wrapped.Count - 1)
                    pageLines.Add(wrapped(index))
                Next
                pages.Add(pageLines)
            Next
            If pages.Count = 0 Then pages.Add(New List(Of String) From {"(no records)"})

            Dim objects As New List(Of String)()
            objects.Add("<< /Type /Catalog /Pages 2 0 R >>")
            objects.Add("") ' filled in after the page objects are numbered
            objects.Add("<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica /Encoding /WinAnsiEncoding >>")

            Dim kids As New List(Of String)()
            For Each page As List(Of String) In pages
                Dim pageObjectNumber As Integer = objects.Count + 1
                Dim contentObjectNumber As Integer = pageObjectNumber + 1
                kids.Add(pageObjectNumber.ToString() & " 0 R")

                Dim pageObject As New StringBuilder()
                pageObject.Append("<< /Type /Page /Parent 2 0 R /MediaBox [0 0 595 842] ")
                pageObject.Append("/Resources << /Font << /F1 3 0 R >> >> ")
                pageObject.Append("/Contents " & contentObjectNumber.ToString() & " 0 R >>")
                objects.Add(pageObject.ToString())

                Dim content As New StringBuilder()
                content.Append("BT /F1 10 Tf 48 792 Td 13 TL" & vbLf)
                For Each line As String In page
                    content.Append("(" & EscapePdf(line) & ") Tj T*" & vbLf)
                Next
                content.Append("ET" & vbLf)

                objects.Add("<< /Length " & Encoding.ASCII.GetByteCount(content.ToString()) & " >>" &
                            vbLf & "stream" & vbLf & content.ToString() & "endstream")
            Next

            objects(1) = "<< /Type /Pages /Kids [" & String.Join(" ", kids) &
                         "] /Count " & pages.Count.ToString() & " >>"

            Dim pdf As New StringBuilder()
            pdf.Append("%PDF-1.4" & vbLf)
            Dim offsets As New List(Of Integer)()
            For index As Integer = 0 To objects.Count - 1
                offsets.Add(Encoding.ASCII.GetByteCount(pdf.ToString()))
                pdf.Append((index + 1).ToString() & " 0 obj" & vbLf)
                pdf.Append(objects(index)).Append(vbLf)
                pdf.Append("endobj" & vbLf)
            Next

            Dim xrefOffset As Integer = Encoding.ASCII.GetByteCount(pdf.ToString())
            pdf.Append("xref" & vbLf)
            pdf.Append("0 " & (objects.Count + 1).ToString() & vbLf)
            pdf.Append("0000000000 65535 f " & vbLf)
            For Each offset As Integer In offsets
                pdf.Append(offset.ToString("D10") & " 00000 n " & vbLf)
            Next
            pdf.Append("trailer" & vbLf)
            pdf.Append("<< /Size " & (objects.Count + 1).ToString() & " /Root 1 0 R >>" & vbLf)
            pdf.Append("startxref" & vbLf)
            pdf.Append(xrefOffset.ToString() & vbLf)
            pdf.Append("%%EOF" & vbLf)

            File.WriteAllText(filePath, pdf.ToString(), Encoding.ASCII)
        End Sub

        Private Function EscapePdf(value As String) As String
            Dim text As String = If(value, "").Replace("\", "\\")
            text = text.Replace("(", "\(").Replace(")", "\)")
            Return text
        End Function

    End Module

End Namespace
