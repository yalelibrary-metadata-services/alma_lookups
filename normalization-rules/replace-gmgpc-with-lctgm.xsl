<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="3.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

  <!-- Copy exact record over -->
  <xsl:mode on-no-match="shallow-copy"/>

  <!-- Replace $2 'gmgpc' with 'lctgm' in 650 and/or 655 and/or 690 when ind2=7 -->
  <xsl:template match="datafield[@tag=('650','655','690')][@ind2='7']/subfield[@code='2']">
    <xsl:copy>
      <xsl:apply-templates select="@*"/>
      <xsl:choose>
        <xsl:when test="normalize-space(.) = 'gmgpc'">
          <xsl:text>lctgm</xsl:text>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="."/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:copy>
  </xsl:template>

<!-- Fix incorrectly concatenated $2 -->
  <!-- Matches patterns like: $2gmgpc, 2gmgpc, $$2gmgpc, etc. -->
  <xsl:template match="datafield[@tag=('650','655','690')][@ind2='7']/subfield[matches(., '.*(\$?\$?2gmgpc).*')]">
    <xsl:copy>
      <xsl:apply-templates select="@*"/>
      <xsl:value-of select="replace(., '(\$?\$?2gmgpc).*$', '')"/>
    </xsl:copy>
    <subfield code="2">lctgm</subfield>
  </xsl:template>

</xsl:stylesheet>
