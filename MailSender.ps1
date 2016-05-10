function MailSender-SendMail {
	param (
		[String]$Sender,
		[String[]]$To,
		[String]$Subject,
		[String]$Body,
		[String]$MailServer,
		[Boolean]$IsBodyHtml,
		[String[]]$Attachments = @()
	)

	$messageParameters = @{
		Subject = $Subject
		Body = $Body
		From = $Sender
		To = $To
		SmtpServer = $MailServer
	}

	if (!!($Attachments) -And $Attachments.Length -gt 0)
	{
		$messageParameters['Attachments'] = $Attachments
	}

	if ($IsBodyHtml)
	{
		$messageParameters['BodyAsHtml'] = $true
	}
	
	Send-MailMessage @messageParameters
}
