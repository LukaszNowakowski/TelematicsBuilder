function MailSender-SendMail {
	param (
		[String]$Sender,
		[String[]]$To,
		[String]$Subject,
		[String]$Body,
		[String]$MailServer,
		[Boolean]$IsBodyHtml,
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
}
