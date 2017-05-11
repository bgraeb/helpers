# Get-MarkdownToc
This cmdlet reads markdown formatted files and returns all headers that are specified in it.

You can use this to automatically create clickable table of contents in markdown files.

## remarks
Needs powershell 5.0 or higher, as I am using a custom powershell class for returning the headers.

## usage
```powershell
Get-MarkdownToc -FilePath MyMarkdown.md -OutputType Toc
```
