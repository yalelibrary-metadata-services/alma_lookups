<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="3.0" 
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:marc="http://www.loc.gov/MARC21/slim">
  
  <xsl:mode on-no-match="shallow-copy"/>
  
  <!-- Load external lookup file -->
  <xsl:variable name="lookup" as="document-node()?" 
    select="document('https://raw.githubusercontent.com/yalelibrary-metadata-services/alma_rules_testing/refs/heads/main/datasets/holdings_record.xml')"/>
  
  <!-- Template for 866 field -->
  <xsl:template match="datafield[@tag='866']">
    <xsl:copy>
      <xsl:apply-templates select="@*"/>
      
      <!-- Get the 852 $h from the current record -->
      <xsl:variable name="call-number-852" select="normalize-space(../datafield[@tag='852']/subfield[@code='h'][1])"/>
      
      <!-- Find matching record in lookup where 099 $a = 852 $h -->
      <xsl:variable name="matching-record" 
        select="$lookup//*[local-name()='record'][*[local-name()='datafield'][@tag='099']/*[local-name()='subfield'][@code='a'][normalize-space(.) = $call-number-852]]"/>
      
      <!-- Get 300 $a from matching record -->
      <xsl:variable name="physical-desc" select="normalize-space($matching-record/*[local-name()='datafield'][@tag='300']/*[local-name()='subfield'][@code='a'])"/>
      
      <!-- Extract just the number (strip "reel" and everything after) -->
      <xsl:variable name="reel-number" select="replace($physical-desc, '(\d+)\s+reel.*', '$1')"/>
      
      <!-- Process subfields -->
      <xsl:for-each select="subfield">
        <xsl:choose>
          <xsl:when test="@code='a' and $reel-number != '' and $reel-number != $physical-desc and $reel-number != '1'">
            <subfield code="a">
              <xsl:text>reel 1-reel </xsl:text>
              <xsl:value-of select="$reel-number"/>
            </subfield>
          </xsl:when>
          <xsl:otherwise>
            <xsl:copy>
              <xsl:apply-templates select="@*|node()"/>
            </xsl:copy>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:for-each>
    </xsl:copy>
  </xsl:template>
  
</xsl:stylesheet>
