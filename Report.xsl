<?xml version="1.0"?>

<xsl:stylesheet version="1.0"
xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

<xsl:template match="/">
<html>
	<head>
		<title>Build report</title>
		<style>
table td, table th {
	line-height: 2;
}

table th:first-child {
	border-left: solid black 2px;
}

table th {
	border-top: solid black 2px;
	border-bottom: solid black 2px;
	border-right: solid black 2px;
}

table tr:first-child td {
	border-top: solid black 1px;
}

table td:first-child {
	border-left: solid black 1px;
}

table td {
	border-bottom: solid black 1px;
	border-right: solid black 1px;
}

.error td {
	background-color: #FF6B6B;
}

.statistics {
	width: 40%;
}

.resultsTable {
	width: 60%;
}

.itemId {
	text-align: center;
	font-weight: bold;
}

.itemDescription {
	text-align: left;
}

.itemStatus {
	text-align: center;
	font-weight: bold;
}
	</style>
	</head>
	<body>
		<h1>CI report</h1>
		<h2>Process report</h2>
		<table class="statistics" cellspacing="0">
			<colgroup>
				<col style="width: 60%" />
				<col />
			</colgroup>
			<tr>
				<td class="itemDescription">
					Start date:
				</td>
				<td class="itemId">
					<xsl:value-of select="Objects/Object/Property[@Name='StartDate']" />
				</td>
			</tr>
			<tr>
				<td class="itemDescription">
					End date:
				</td>
				<td class="itemId">
					<xsl:value-of select="Objects/Object/Property[@Name='EndDate']" />
				</td>
			</tr>
		</table>
		<h2>GIT report</h2>
		<table class="statistics" cellspacing="0">
			<colgroup>
				<col style="width: 60%" />
				<col />
			</colgroup>
			<tr>
				<td class="itemDescription">
					Download start date:
				</td>
				<td class="itemId">
					<xsl:value-of select="Objects/Object/Property[@Name='GitDownloadStart']" />
				</td>
			</tr>
			<tr>
				<td class="itemDescription">
					Download end date:
				</td>
				<td class="itemId">
					<xsl:value-of select="Objects/Object/Property[@Name='GitDownloadEnd']" />
				</td>
			</tr>
			<tr>
				<td class="itemDescription">
					Commit start date:
				</td>
				<td class="itemId">
					<xsl:value-of select="Objects/Object/Property[@Name='GitCommitStart']" />
				</td>
			</tr>
			<tr>
				<td class="itemDescription">
					Commit end date:
				</td>
				<td class="itemId">
					<xsl:value-of select="Objects/Object/Property[@Name='GitCommitEnd']" />
				</td>
			</tr>		</table>
		<h2>Build report</h2>
		<table class="statistics" cellspacing="0">
			<colgroup>
				<col style="width: 60%" />
				<col />
			</colgroup>
			<tr>
				<td class="itemDescription">
					Build start date:
				</td>
				<td class="itemId">
					<xsl:value-of select="Objects/Object/Property[@Name='BuildResults']/Property/Property[@Name='BuildStart']" />
				</td>
			</tr>
			<tr>
				<td class="itemDescription">
					Build end date:
				</td>
				<td class="itemId">
					<xsl:value-of select="Objects/Object/Property[@Name='BuildResults']/Property/Property[@Name='BuildEnd']" />
				</td>
			</tr>
			<tr>
				<td class="itemDescription">
					Failed builds:
				</td>
				<td class="itemId">
					<xsl:value-of select="Objects/Object/Property[@Name='BuildResults']/Property/Property[@Name='Failed']" />
				</td>
			</tr>
			<tr>
				<td class="itemDescription">
					Succeeded builds:
				</td>
				<td class="itemId">
					<xsl:value-of select="Objects/Object/Property[@Name='BuildResults']/Property/Property[@Name='Succeeded']" />
				</td>
			</tr>
		</table>
		<div style="height: 30px;">
			<xsl:text disable-output-escaping="yes"><![CDATA[&nbsp;]]></xsl:text>
		</div>
		<table class="resultsTable" cellspacing="0">
			<colgroup>
				<col style="width: 10%;" />
				<col style="width: 60%;" />
				<col />
			</colgroup>
			<thead>
				<tr>
					<th>Id</th>
					<th>Solution</th>
					<th>Build result</th>
				</tr>
			</thead>
			<tbody>
				<xsl:for-each select="Objects/Object/Property[@Name='BuildResults']/Property/Property[@Name='Solutions']/Property">
					<xsl:element name="tr">
						<xsl:if test="Property[@Name='Succeeded'] = 'False'">
							<xsl:attribute name="class">error</xsl:attribute>
						</xsl:if>
						<td class="itemId"><xsl:value-of select="position()" /></td>
						<td class="itemDescription"><xsl:value-of select="Property[@Name='SolutionName']" /></td>
						<td class="itemStatus">
							<xsl:choose>
								<xsl:when test="Property[@Name='Succeeded'] = 'True'">Succeeded</xsl:when>
								<xsl:when test="Property[@Name='Succeeded'] = 'False'">Failed</xsl:when>
							</xsl:choose>
						</td>
					</xsl:element>
				</xsl:for-each>
			</tbody>
		</table>
	</body>
</html>
</xsl:template>
</xsl:stylesheet>