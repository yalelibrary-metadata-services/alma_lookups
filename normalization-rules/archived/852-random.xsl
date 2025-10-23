<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="3.0" 
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
  
  <xsl:mode on-no-match="shallow-copy"/>
  
  <xsl:template match="datafield[@tag='852']">
    <xsl:copy>
      <xsl:apply-templates select="@*"/>
      <xsl:apply-templates select="subfield"/>
      
      <!-- Generate random number + 4 random letters -->
      <xsl:variable name="letters" select="'ABCDEFGHIJKLMNOPQRSTUVWXYZ'"/>
      <xsl:variable name="rng" select="random-number-generator()"/>
      
      <subfield code="h">
        <xsl:text>TEMP_</xsl:text>
        <xsl:value-of select="format-number($rng?number * 1000000, '000000')"/>
        <xsl:text>_</xsl:text>
        <!-- Generate 4 random letters -->
        <xsl:value-of select="substring($letters, floor($rng?next()?number * 26) + 1, 1)"/>
        <xsl:value-of select="substring($letters, floor($rng?next()?next()?number * 26) + 1, 1)"/>
        <xsl:value-of select="substring($letters, floor($rng?next()?next()?next()?number * 26) + 1, 1)"/>
        <xsl:value-of select="substring($letters, floor($rng?next()?next()?next()?next()?number * 26) + 1, 1)"/>
      </subfield>
    </xsl:copy>
  </xsl:template>
  
</xsl:stylesheet>
