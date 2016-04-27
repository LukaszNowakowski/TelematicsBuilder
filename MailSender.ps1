param (
    [parameter(Position=0,Mandatory=$true,ValueFromPipeline=$true,HelpMessage="Sender of the message.")]
	[ValidateNotNullOrEmpty()]
	[String]$Sender,
    [parameter(Position=1,Mandatory=$true,ValueFromPipeline=$true,HelpMessage="Message receiver.")]
	[ValidateNotNullOrEmpty()]
	[String[]]$To,
    [parameter(Position=3,Mandatory=$true,ValueFromPipeline=$true,HelpMessage="Mail subject.")]
	[ValidateNotNullOrEmpty()]
	[String]$Subject,
    [parameter(Position=4,Mandatory=$true,ValueFromPipeline=$true,HelpMessage="Mail body.")]
	[ValidateNotNullOrEmpty()]
	[String]$Body,
    [parameter(Position=5,Mandatory=$true,ValueFromPipeline=$true,HelpMessage="Mail server address.")]
	[ValidateNotNullOrEmpty()]
	[String]$MailServer,
	[parameter(Position=6,Mandatory=$false,ValueFromPipeline=$true,HelpMessage="Is body HTML.")]
	[Boolean]$IsBodyHtml,
    [parameter(Position=7,Mandatory=$false,ValueFromPipeline=$true,HelpMessage="Array of file paths to be attached.")]
	[ValidateNotNullOrEmpty()]
	[String[]]$Attachments
)

if ($IsBodyHtml)
{
	Send-MailMessage -SmtpServer $MailServer -From $Sender -To $To -Subject $Subject -Body $Body -BodyAsHtml -Attachments $Attachments
}
else
{
	Send-MailMessage -SmtpServer $MailServer -From $Sender -To $To -Subject $Subject -Body $Body -Attachments $Attachments
}
