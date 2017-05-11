function Get-MarkdownToc {
    param(
        #Markdown file to analyze
        $Filepath,
        #Fileencoding
        [ValidateSet(
            "Unknown",
            "String",
            "Unicode",
            "Byte",
            "BigEndianUnicode",
            "UTF8",
            "UTF7",
            "UTF32",
            "Ascii",
            "Default",
            "Oem",
            "BigEndianUTF32"
        )]
        $Encoding = 'Ascii',
        #OutputType to return
        [ValidateSet(
            'Objects',
            'Toc',
            'Overview'
        )]
        $OutPutType = 'Overview'
    )
    $file = get-item $filepath

    $content = (get-content $file -Encoding $Encoding ) -join "`n"

    class MarkDownHeader {
        [int]$IntLayer
        [string]$StringLayer
        [string]$Name
        [string]$Raw
        [MdType]$HeaderType
        [string]$MdLinkString
        MarkDownHeader ([string]$raw, [string]$name, [string]$StringLayer) {
            $this.StringLayer = $StringLayer
            if ($StringLayer -match '-|=') {
                $this.HeaderType = 'setex'
                if ($this.StringLayer -match '-') {
                    $this.IntLayer = 2
                }
                else {
                    $this.IntLayer = 1
                }
            }
            else {
                $this.HeaderType = 'atx'
                $this.IntLayer = $StringLayer.Length
            }
            $this.name = $name
            $this.raw = $raw
            $this.MdLinkString = '{0}- [{1}](#{2})' -f ('    ' * ($this.IntLayer - 1)), $this.name, ($this.name.ToLower() -replace ' ', '-')
        }
    }
    Enum MdType{
        atx
        setex
    }

    $regex = '(?<name>[^\n\r]+)\n(?<StringLayer>[-|=]{2,})$|^((?<StringLayer>#{1,6})\s*(?<name>.+))$'

    $options = [text.regularexpressions.regexoptions]::Multiline

    $headerObjects = [regex]::Matches($content, $regex, $options) | ForEach-Object { 
        $name = $_.groups | Where-Object {$_.success -eq 'true' -and $_.name -eq 'name'} | Select-Object -ExpandProperty value
        $StringLayer = $_.groups | Where-Object {$_.success -eq 'true' -and $_.name -eq 'StringLayer'} | Select-Object -ExpandProperty value
        $raw = $_.groups[0].value
        [markdownheader]::new($raw, $name, $StringLayer)
    }

    switch ($OutPutType) {
        'Objects'{
            $headerObjects
        }
        'Toc'{
            $outString = @()
            $outString += '**Table of contents**'
            $outString += $headerObjects.MdLinkString
            $outString | Out-String
        }
        'Overview'{
            $headerObjects | ForEach-Object { '{0}- {1}' -f ('  ' * ($_.IntLayer-1)), $_.Name
            }
        }
    }

}